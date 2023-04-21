## H.264 Encoder

The project is divided into 3 parts.

1. **Main Code:** H.264 Encoding module converted from becattles's implementation: [hardh264](https://github.com/bcattle/hardh264).
2. **Inter Prediction**: Module for H.264 standard interprediction.
3. **Data Handling**: It contains a state machine for handling the data input to the h264 encoding module.

## Build and Simulate

### Main H.264 Encoder

Goto top directory and run the command

``` ./make_encode.bat ```

### Inter Prediction Module

Goto top directory and run the command

``` ./make_me.bat ```

### Data Handler

Goto top directory and run the command

``` ./make_pixel_addr.bat ```

## Inter Prediction Design

### Variable Block Size Motion Estimator

_Design is only drawn for PE Order 2x2_

![vbs_me](https://github.com/hamza-akhtar-dev/h264encoder/blob/media/vbs_me.png?raw=true)

### Simulation

Design is simulated with all pixels having value 0x11 in current picture and 0x00 in reference picture. The SAD value should be ``` 0x11 * 0x100 ``` or ``` 17 * 256 ```. This is equal to ``` 0x1100 ``` or ``` 4352 ```. Result is highlighted in the waveform.

![waveform_me](https://github.com/hamza-akhtar-dev/h264encoder/blob/media/waveform_me.png?raw=true)

### Elaboration

The eloborated schematic of the design is shown below.

![schematic_me](https://github.com/hamza-akhtar-dev/h264encoder/blob/media/schematic_me.png?raw=true)
