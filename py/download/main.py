#!/usr/bin/env python

import os
import argparse
import asyncio
import aiohttp
from aiohttp import ClientTimeout
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse, quote
import logging
from asyncio import Semaphore

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Configure the maximum number of concurrent requests and retry limit
MAX_CONCURRENT_REQUESTS = 10
RETRY_LIMIT = 5

# Semaphore to limit the number of concurrent requests
semaphore = Semaphore(MAX_CONCURRENT_REQUESTS)

# Timeout configuration for aiohttp
TIMEOUT = ClientTimeout(total=20)

# List to store failed downloads
failed_downloads = []

# File extensions
DOC_EXTENSIONS = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.txt', '.ppt', '.pptx', '.csv', '.zip', '.rar']
VID_EXTENSIONS = ['.mp4', '.webm', '.mkv', '.avi', '.mov', '.flv', '.wmv', '.mpeg', '.3gp', '.m4v', '.ogg']
AUD_EXTENSIONS = ['.mp3', '.ogg', '.wav', '.flac', '.aac', '.m4a', '.wma', '.opus', '.aiff']
IMG_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg']

# Function to create directories recursively based on URL structure
def create_directory_structure(file_url):
    parsed_url = urlparse(file_url)
    path_parts = [quote(part) for part in parsed_url.netloc.split('.')] + [quote(part) for part in parsed_url.path.split('/')[:-1]]
    path = os.path.join(*path_parts)
    os.makedirs(path, exist_ok=True)  # Avoid creating duplicates
    return path

# Function to handle file name conflicts
def get_unique_file_name(file_path):
    if not os.path.exists(file_path):
        return file_path

    base, ext = os.path.splitext(file_path)
    counter = 2
    new_file_path = f"{base} ({counter}){ext}"
    while os.path.exists(new_file_path):
        counter += 1
        new_file_path = f"{base} ({counter}){ext}"
    return new_file_path

# Function to check if a link is valid for fetching
def is_valid_link(base_url, link):
    parsed_base = urlparse(base_url)
    parsed_link = urlparse(link)

    # Allow links from the same domain or subdomains, or links that are under the base directory
    if parsed_link.netloc == "" or parsed_link.netloc == parsed_base.netloc or parsed_link.netloc.endswith(parsed_base.netloc):
        return True
    return False

# Exponential backoff function
def get_backoff_time(retry_count):
    return min(2 ** retry_count, 32)  # Cap the backoff time at 32 seconds

# Asynchronous function to download a file
async def download_file(session, file_url, visited):
    async with semaphore:
        for attempt in range(RETRY_LIMIT):
            try:
                if file_url in visited:
                    logging.info(f"Already downloaded: {file_url}")
                    return
                
                dir_path = create_directory_structure(file_url)
                file_name = os.path.join(dir_path, os.path.basename(file_url))
                file_name = get_unique_file_name(file_name)

                logging.info(f"Downloading {os.path.basename(file_name)}")

                async with session.get(file_url, timeout=TIMEOUT) as response:
                    response.raise_for_status()
                    with open(file_name, 'wb') as file:
                        async for chunk in response.content.iter_any(1024):
                            if chunk:
                                file.write(chunk)

                logging.info(f"Downloaded: {file_url}")
                visited.add(file_url)  # Mark this file as visited
                return

            except Exception as e:
                logging.error(f"Failed to download {file_url} on attempt {attempt + 1}: {e}")
                if attempt < RETRY_LIMIT - 1:
                    backoff_time = get_backoff_time(attempt)
                    logging.info(f"Retrying {file_url} after {backoff_time} seconds...")
                    await asyncio.sleep(backoff_time)
                else:
                    logging.error(f"Failed to download {file_url} after {RETRY_LIMIT} attempts.")
                    failed_downloads.append(file_url)

# Modify how URLs are constructed
async def get_files(session, base_url, base_directory, extensions, visited=None, download=False):
    if visited is None:
        visited = set()

    if base_url in visited:
        return
    visited.add(base_url)

    async with semaphore:
        for attempt in range(RETRY_LIMIT):
            try:
                async with session.get(base_url, timeout=TIMEOUT, headers={'User-Agent': 'Mozilla/5.0'}) as response:
                    response.raise_for_status()
                    content = await response.text()
                break  # Exit loop on success
            except aiohttp.ClientResponseError as e:
                if e.status in (502,):
                    logging.error(f"Bad Gateway (502) for {base_url}: {e}")
                    await asyncio.sleep(2)
                    continue  # Retry the request
                logging.error(f"Error fetching {base_url}: {e}")
                return
            except Exception as e:
                logging.error(f"Unexpected error fetching {base_url}: {e}")
                return

    soup = BeautifulSoup(content, 'html.parser')
    tasks = []

    for link in soup.find_all('a', href=True):
        href = link['href']

        # Skip unwanted links
        if href.startswith('javascript:') or href.startswith('mailto:'):
            continue

        # Form the URL correctly
        full_url = urljoin(base_url, href)

        # Check if the URL ends with any of the desired extensions
        if any(full_url.lower().endswith(ext) for ext in extensions):
            if download:
                tasks.append(asyncio.create_task(download_file(session, full_url, visited)))
            else:
                logging.info(f"Found file: {full_url}")

        # Explore links recursively, allowing external links under the current directory
        if is_valid_link(base_url, full_url):
            tasks.append(asyncio.create_task(get_files(session, full_url, base_directory, extensions, visited, download)))

    await asyncio.gather(*tasks)

# Main function to handle multiple websites and optional download
async def main(websites, extensions, download):
    async with aiohttp.ClientSession() as session:
        tasks = []
        for website in websites:
            logging.info(f"Scanning website: {website}")
            base_directory = website
            tasks.append(get_files(session, website, base_directory, extensions, download=download))

        await asyncio.gather(*tasks)

        if download and failed_downloads:
            logging.error(f"Total failed downloads after retries: {len(failed_downloads)}")
            for failed_url in failed_downloads:
                logging.error(f"Failed: {failed_url}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Recursively find and optionally download files from websites based on extensions.")
    parser.add_argument('websites', metavar='website', type=str, nargs='+',
                        help='List of websites to scan for files')
    parser.add_argument('-e', '--extensions', metavar='extension', type=str, nargs='+', default=['pdf'],
                        help='List of file extensions to search for (e.g., pdf, mp4, mp3, or !DOC, !VID, !AUD, !IMG)')
    parser.add_argument('-d', '--download', action='store_true',
                        help='Download the found files')

    args = parser.parse_args()

    # Handle special groups like !DOC, !VID, !AUD, !IMG
    extensions = []
    if args.extensions:
        for ext in args.extensions:
            if ext == '!DOC':
                extensions.extend(DOC_EXTENSIONS)
            elif ext == '!VID':
                extensions.extend(VID_EXTENSIONS)
            elif ext == '!AUD':
                extensions.extend(AUD_EXTENSIONS)
            elif ext == '!IMG':
                extensions.extend(IMG_EXTENSIONS)
            else:
                extensions.append(f".{ext.strip('.')}")

    # Start the asyncio event loop
    asyncio.run(main(args.websites, extensions, args.download))
