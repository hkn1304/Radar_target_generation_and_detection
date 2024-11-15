# Radar_target_generation_and_detection


![project_layout](https://github.com/user-attachments/assets/445649ed-cfc7-4bc5-ae96-183afb54ac25)


| Design Param    | Value  |
| -------------   | -------|
| Frequency       | 77 GHz |
| Range Resolution| 1 m    |
| Max Range       | 200 m  |
| Max Velocity    | 100 m/s|
| Veloc Resolution| 1 m/s  |


![signal_propagation](https://github.com/user-attachments/assets/47a4618b-ccae-4899-bb0a-34600ab1d4c4)



# Selection of Training & Guard Cells
![2D_CFAR_cells](https://github.com/user-attachments/assets/393e0fb5-c427-40ab-98b1-e2042fbda774)
The selection of Training cells, Guard cells and offset need to be chosen based on the specific environment and system configuration. If a dense traffic situation were to happen, then fewer training cells should be used - closely spaced targets can impact the noise estimate. The number of guard cells on the other hand should be chosen based on the leakage of the target signal out of the cell under test. In general, the number of leading and lagging training cells are the same. The offset value should be based on the leakage of the target signal to allow valid targets to be detected at the same time suppresses the clutter noise


| CFAR Param          | ^#   |
| -----------------   | -----|
| Range - Train Cell #|   10 |
| Doppler-Train Cell #|    7 |
| Range - Guard Cell #|    4 |
| Doppler-Guard Cell #|    4 |
| Threshold Factor    |   1.7|

# 2D CFAR Implementation Steps:
* Determine the number of Training cells for each dimension. Similarly, pick the number of guard cells.
* Slide the cell under test across the complete matrix. Make sure the CUT has margin for Training and Guard cells from the edges.
* For every iteration sum the signal level within all the training cells. To sum convert the value from logarithmic to linear using db2pow function.
* Average the summed values for all of the training cells used. After averaging convert it back to logarithmic using pow2db.
* Add the offset to it to determine the threshold.
* Compare the signal under CUT against this threshold.
* If the CUT level > threshold assign it a value of 1, else equate it to 0.

# Assignment Comments:
Congratulations on completing this project! You’ve successfully passed all the specifications! The generated images look excellent and the 2D CFAR processing was able to suppress the noise and separate the target signal. You have a good understanding of the core concepts of how to generate the target, FMCW waveform creation and processing techniques like FFT, CFAR to create the Range Doppler Maps (RDM).
I had a wonderful time reviewing your project. Good luck with the rest of the course!
