# DGF High-Profit Risk-Shape Rejection Note

The current-source DGF high-profit risk-shape screen rejected simple risk scaling as a path to money readiness.

The control, `dgf_hp_control`, reproduced the high-profit continuous Model4 result at `+$1,915.83`, `25.45%/yr`, PF `1.72`, `127` trades, and `24.58%` drawdown. Lower base-risk settings from `0.50%` through `0.80%` did not reduce the same edge cleanly; they produced losing curves with `31-33%` drawdown. Loss scaling helped only slightly: `dgf_hp_risk080_loss_scale` made `+$238.06`, but with `20.13%` drawdown and recovery `0.76`.

Late equity profit locks also failed to create a better shape. `35%/70%` had no effect versus the control, while `20%/70%` reduced profit to `+$75.90` and still left `22.26%` drawdown.

Decision: keep `lossblock_highprofit_peaktrail_off` as a high-profit research reference only. Do not promote any risk-shaped variant from this package.
