# Design and development of an embedded system for remote monitoring the water level of a tank

## Overview

In this thesis, the design and construction of a system for collecting data from the field was carried out. In particular the system monitors the filling level of a tank. 
A microcontroller is used for level detection and data transmission, an Arduino MKR GSM 1400 and an ultrasonic sensor HC-SR04 complete this task. The collected data is sent to a cloud via APIs issued by a framework called Measurify. The project also includes a smartphone application, developed using Flutter, the app essentially consists of 3 screens where you can view the level in real time, a graph showing the trend of the last 24 hours and finally set the various operating parameters of the system.