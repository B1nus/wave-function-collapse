This is an implementation of the Wave Function Collapse algorithm in Godot 4.2.2 using Tilemaps. It's a very simple and naive implementation, sometimes it attempts to place impossible tiles, my solution is to simply remove all tiles in a radius and try the wave function collapse algorithm again, which works. Sort of, it's a bit glitchy. One cool thing is that more common blocks in the sample (The tilemap in the main scene) are plced more often, so it's quite good att recreating the feel of the sample. I see potential in this sort of a system, but it sure does need some work and some pretty substantial modifications.
