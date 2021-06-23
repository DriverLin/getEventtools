# -*- coding: utf-8 -*-
# Time : 2019/2/7 12:40
# Author : hubozhi
import pygame
from pygame.locals import *
from sys import exit
from pygame.math import *
from math import *
import socket
udpSocket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sendArr = ('192.168.18.104', 8848)
# sendArr = ('192.168.1.156', 8848)
# udpSocket.sendto(str(event.Scancode+100000000).encode('utf-8'), sendArr)


mouse_mapper = {
    1: 272,
    3: 273,
}

key_mapper = {42: 14, 43: 15, 40: 28, 225: 42, 224: 29, 226: 56, 57: 58, 41: 1, 44: 57, 74: 102, 80: 105, 82: 103, 79: 106, 81: 108, 70: 210, 73: 110, 76: 111, 39: 11, 30: 2, 31: 3, 32: 4, 33: 5, 34: 6, 35: 7, 36: 8, 37: 9, 38: 10,
              4: 30, 5: 48, 6: 46, 7: 32, 8: 18, 9: 33, 10: 34, 11: 35, 12: 23, 13: 36, 14: 37, 15: 38, 16: 50, 17: 49, 18: 24, 19: 25, 20: 16, 21: 19, 22: 31, 23: 20, 24: 22, 25: 47, 26: 17, 27: 45, 28: 21, 29: 44, 83: 69, 71: 70, 53: 41}
if __name__ == "__main__":
    pygame.init()
    screen = pygame.display.set_mode((320, 240), 0, 32)
    pygame.mouse.set_visible(False)
    pygame.event.set_grab(True)
    while True:
        for event in pygame.event.get():
            if event.type == QUIT:
                exit()
            if event.type == KEYDOWN:
                # print(event.scancode, event.scancode in key_mapper)
                if event.key == K_ESCAPE:
                    exit()
                else:
                    if event.scancode in key_mapper:
                        udpSocket.sendto(
                            str(key_mapper[event.scancode]+100000000).encode('utf-8'), sendArr)
            elif event.type == KEYUP:
                if event.scancode in key_mapper:
                    udpSocket.sendto(
                        str(key_mapper[event.scancode]+200000000).encode('utf-8'), sendArr)
                pass
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button in mouse_mapper:
                    udpSocket.sendto(
                        str(mouse_mapper[event.button]+100000000).encode('utf-8'), sendArr)
            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button in mouse_mapper:
                    udpSocket.sendto(
                        str(mouse_mapper[event.button]+200000000).encode('utf-8'), sendArr)
            elif event.type == pygame.MOUSEMOTION:
                rel = pygame.mouse.get_rel()
                if rel[0] or rel[1]:
                    udpSocket.sendto(str(
                        (100000000+rel[0]*10000) % 100000000 + (rel[1]+10000) % 10000).encode('utf-8'), sendArr)
            elif event.type == pygame.MOUSEWHEEL:
                print(event.y)
                udpSocket.sendto(
                    str(5000+event.y+300000000).encode('utf-8'), sendArr)
