import carla
import numpy as np
import pandas as pd
import time

# ==================== اتصال به CARLA =====================
client = carla.Client('localhost', 2000)
client.set_timeout(10.0)
world = client.get_world()

# انتخاب ماشین خودمختار (غیرفعال کردن Autopilot)
blueprint_library = world.get_blueprint_library()
vehicle_bp = blueprint_library.filter('vehicle.tesla.model3')[0]
spawn_point = carla.Transform(carla.Location(x=-41.85, y=-30.44, z=0.5), carla.Rotation(yaw=-89.57))
vehicle = world.spawn_actor(vehicle_bp, spawn_point)
vehicle.set_autopilot(False)

# ==================== بارگذاری مسیر مرجع از CSV =====================
df = pd.read_csv("D:\\Adaptive Control\\autopilot_data_20250729_234704.csv")
reference_data = df[['x', 'y', 'speed', 'yaw']].to_numpy()
dt = 0.05
sim_time = 70
steps = int(sim_time / dt)

# ==================== مدل مرجع =====================
AM = np.array([[1.00176536, 0., 0., 0.],
               [0., 0.99738321, 0., 0.],
               [0., 0., 0.9287813, 0.],
               [0., 0., 0., 0.97971263]])

BM = np.array([[ 0.07075442,  0.04591283,  3.61660205,  0.23144604],
               [ 0.0584045,   0.19913708, -7.21824105, -0.01847172],
               [ 0.08392217,  0.06304376,  3.46838312, -0.08955975]])

P = np.eye(4)  # حل معادله لیاپانوف (ساده‌سازی‌شده)
Gamma = 0.5 * np.eye(12)  # نرخ تطبیق
sigma = 0.1  # e-modification coefficient

# ==================== مقداردهی اولیه =====================
w_hat = np.zeros((12, 1))  # بردار تخمین ضرایب (4x3 کنترل درایه‌ای)
theta_rls = np.zeros((12, 1))
P_rls = 1000 * np.eye(12)

# ذخیره‌سازی لاگ‌ها
log_data = []

# ==================== شبیه‌سازی =====================
for t in range(steps):
    ref = reference_data[t]
    x_ref = ref.reshape(-1, 1)  # [x, y, speed, yaw]

    # دریافت وضعیت فعلی
    transform = vehicle.get_transform()
    velocity = vehicle.get_velocity()
    x = np.array([
        [transform.location.x],
        [transform.location.y],
        [np.linalg.norm([velocity.x, velocity.y])],
        [np.deg2rad(transform.rotation.yaw)]
    ])

    # خطای حالت
    e = x - x_ref

    # بردار رگرسور برای کنترل: phi = kron(x.T, I3)
    phi = np.kron(x.T, np.eye(3))  # (3x12)

    # ==================== کنترل تطبیقی =====================
    u_adapt = - (phi @ w_hat).reshape(-1, 1)  # کنترل تطبیقی با ضرایب تخمین زده‌شده
    u_adapt = np.clip(u_adapt, [-1.0, -1.0, -1.0], [1.0, 1.0, 1.0])

    # فرمان دادن به خودرو
    throttle = float(np.clip(u_adapt[0, 0], 0, 1))
    brake = float(np.clip(-u_adapt[1, 0], 0, 1))
    steer = float(np.clip(u_adapt[2, 0], -1, 1))
    vehicle.apply_control(carla.VehicleControl(throttle=throttle, brake=brake, steer=steer))

    # ==================== قانون تطبیق لیاپانوف =====================
    e_mod = e + sigma * np.linalg.norm(e) * e
    w_hat_dot = -Gamma @ (phi.T @ P @ e_mod)
    w_hat += w_hat_dot * dt

    # ==================== تخمین پارامتر با RLS =====================
    y_rls = (x - AM @ x) / dt  # مشتق تقریبی
    phi_rls = phi.T
    error_rls = y_rls - phi_rls @ theta_rls
    gain = P_rls @ phi_rls.T @ np.linalg.inv(np.eye(1) + phi_rls @ P_rls @ phi_rls.T)
    theta_rls += gain @ error_rls
    P_rls = P_rls - gain @ phi_rls @ P_rls

    # ذخیره‌سازی داده‌ها برای تحلیل
    log_data.append({
        "t": t * dt,
        "x": x.flatten(),
        "x_ref": x_ref.flatten(),
        "e": e.flatten(),
        "w_hat": w_hat.flatten(),
        "theta_rls": theta_rls.flatten(),
        "u": u_adapt.flatten()
    })

    time.sleep(dt)

# ==================== آزادسازی منابع =====================
vehicle.destroy()
print("Simulation finished.")

# ==================== ذخیره‌سازی لاگ =====================
import pickle
with open("mrac_rls_logs.pkl", "wb") as f:
    pickle.dump(log_data, f)
