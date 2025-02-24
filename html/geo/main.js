const nav = document.querySelector('nav');
const animation = document.querySelector('.animation');
const links = document.querySelectorAll('nav a');
let activeLink = document.querySelector('nav a.active'); // Store the active link

// Function to set the width and position of the animation smoothly
function setAnimation(el) {
    const width = el.offsetWidth;
    const left = el.offsetLeft;
    animation.style.width = `${width}px`;
    animation.style.left = `${left}px`;
}

// Function to check and set the active link on page load and after resize
function updateActiveLink() {
    if (activeLink) {
        setAnimation(activeLink);
    } else {
        setAnimation(links[0]); // Fallback to first link if none is active
    }
}

// Set the initial animation position on load
updateActiveLink();

// Add hover effect for each link
links.forEach(link => {
    link.addEventListener('mouseover', function() {
        setAnimation(this);  // Move animation to the hovered link
    });
});

// Reset to the active link's position when the mouse leaves the nav
nav.addEventListener('mouseleave', function() {
    updateActiveLink(); // Return animation to the active link
});

// Adjust animation on window resize (including zoom)
window.addEventListener('resize', function() {
    // Recalculate position and width for active link on resize or zoom
    updateActiveLink();

    // Dynamically adjust font-size for better responsiveness on zoom
    links.forEach(link => {
        let fontSize = Math.min(window.innerWidth * 0.020, 20); // Max font-size is 20px
        link.style.fontSize = `${fontSize}px`;  // Adjust font-size dynamically
    });
});

// Trigger the initial resize event to set responsive font size on page load
window.dispatchEvent(new Event('resize'));
