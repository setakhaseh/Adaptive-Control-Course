import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression

# آدرس فایل CSV
csv_path = r"D:\Adaptive Control\autopilot_data_20250730_111800.csv"

# خواندن داده‌ها
df = pd.read_csv(csv_path)

# استخراج متغیرها
x = df['x'].values
y = df['y'].values
yaw = df['yaw'].values
speed = df['speed_mps'].values
throttle = df['throttle'].values
steer = df['steer'].values
brake = df['brake'].values

# تعداد نمونه‌ها
N = len(x)

# آماده‌سازی ماتریس ویژگی‌ها (X_t-1, u_t)
X_reg = np.column_stack([
    x[:-1], y[:-1], yaw[:-1], speed[:-1],  # حالت‌ها در t-1
    throttle[1:], steer[1:], brake[1:]    # ورودی‌ها در t
])

# تعریف توابع رگرسیون برای هر متغیر خروجی
def estimate_ABCD(y_output, name):
    model = LinearRegression()
    model.fit(X_reg, y_output[1:])
    coeffs = model.coef_

    A = coeffs[["x", "y", "yaw", "speed"].index(name)]
    B = coeffs[4]
    C = coeffs[5]
    D = coeffs[6]

    return A, B, C, D

# برآورد ضرایب برای هر معادله
Ax, Bx, Cx, Dx = estimate_ABCD(x, "x")
Ay, By, Cy, Dy = estimate_ABCD(y, "y")
Ayaw, Byaw, Cyaw, Dyaw = estimate_ABCD(yaw, "yaw")
Aspeed, Bspeed, Cspeed, Dspeed = estimate_ABCD(speed, "speed")

# ساخت ماتریس‌ها
AM = np.diag([Ax, Ay, Ayaw, Aspeed])
BM = np.array([
    [Bx, By, Byaw, Bspeed],
    [Cx, Cy, Cyaw, Cspeed],
    [Dx, Dy, Dyaw, Dspeed]
])

# نمایش نتایج
print("AM =\n", AM)
print("\nBM =\n", BM)
