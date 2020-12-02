# Colors and saves movies of a Chimera model from various angles

# Imports
import getopt, sys # Allows for command line arguments
import os


file_handle = open('MDframes.ctl', 'r')
lines_list = file_handle.readlines()
print lines_list
framenumberline=lines_list[0].split()
print framenumberline
frame_number = framenumberline[1]
print frame_number
framestepline=lines_list[1].split()
print framestepline
frame_step = framestepline[1]
print frame_step
print lines_list
framegroupline=lines_list[2].split()
print framegroupline
frame_groups = framegroupline[1]
print frame_groups

