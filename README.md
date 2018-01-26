# Rendering on FPGA
An implementation of 3D renderer on Terasic DE2-115 FPGA board

## Requirements
* Quartus 15
* DE2-115 FPGA board

## Description
Real-time 3D Renderer on DE2-115 using NIOS II

**Demo**: https://www.youtube.com/watch?v=2jhcZfhmaCM

Running a simple 3D rendering program on DE2-115

Currently using Nios II w/ Floating Point Hardware 2

Program written in C89

Rendering is based on rasterization, which is normally faster than ray-tracing.

## Features
* Reading .obj model file from SD card
* Reading .png texture file from SD card
* Camera control with keyboard and mouse (Movement: WASD; View: IJKL or mouse)
* Resolution: 320x240 scaled to 640x480 VGA
* Frame rate: about 3~5 fps