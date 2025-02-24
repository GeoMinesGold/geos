#!/usr/bin/env python

x = input("Enter the first number: ")
if not x.isdigit():
    while not x.isdigit():
        x = input("Enter a valid number: ")
x = int(x)

y = input("Enter the second number: ")
if not y.isdigit():
    while not y.isdigit():
        y = input("Enter a valid number: ")
y = int(y)

z = input("Choose the operation from the options:\n1) *\n2) /\n3) +\n4) -\n") 
z = int(z)

if z == 1:
    print(x * y)
elif z == 2:
    print(x / y)
elif z == 3:
    print(x + y)
elif z == 4:
    print(x - y)
