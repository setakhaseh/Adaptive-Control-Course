import carla
import time
import csv
import os
import math

# اتصال به سرور CARLA
client = carla.Client('localhost', 2000)
client.set_timeout(10.0)

# دسترسی به دنیا و تنظیمات
world = client.get_world()
blueprint_library = world.get_blueprint_library()

# انتخاب ماشین
vehicle_bp = blueprint_library.filter('vehicle.tesla.model3')[0]

# انتخاب نقطه شروع
spawn_points = world.get_map().get_spawn_points()
spawn_point = spawn_points[0]

# اسپاون ماشین
vehicle = world.spawn_actor(vehicle_bp, spawn_point)

# فعال‌سازی Autopilot
vehicle.set_autopilot(True)

# لیست ذخیره داده
data = []

# مدت زمان جمع‌آوری داده (ثانیه)
DURATION = 30  # مثلاً 30 ثانیه
INTERVAL = 0.1  # هر ۰.۱ ثانیه
steps = int(DURATION / INTERVAL)

# تابع تبدیل بردار به norm
def get_speed(velocity):
    return math.sqrt(velocity.x**2 + velocity.y**2 + velocity.z**2)

try:
    for step in range(steps):
        transform = vehicle.get_transform()
        location = transform.location
        rotation = transform.rotation

        velocity = vehicle.get_velocity()
        angular_velocity = vehicle.get_angular_velocity()
        acceleration = vehicle.get_acceleration()

        timestamp = world.get_snapshot().timestamp.elapsed_seconds

        # ذخیره‌سازی داده
        data.append([
            timestamp,
            location.x, location.y, location.z,
            rotation.pitch, rotation.yaw, rotation.roll,
            velocity.x, velocity.y, velocity.z,
            angular_velocity.x, angular_velocity.y, angular_velocity.z,
            acceleration.x, acceleration.y, acceleration.z
        ])

        print(f"Step {step+1}/{steps} | Time: {timestamp:.2f}")

        time.sleep(INTERVAL)

finally:
    print("پایان شبیه‌سازی. ذخیره داده‌ها...")

    # ذخیره در CSV
    filename = r"D:\Adaptive Control\reference_vehicle_data.csv"

    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            "time",
            "x", "y", "z",
            "pitch", "yaw", "roll",
            "vel_x", "vel_y", "vel_z",
            "ang_vel_x", "ang_vel_y", "ang_vel_z",
            "acc_x", "acc_y", "acc_z"
        ])
        writer.writerows(data)

    print(f"✅ داده‌ها در فایل '{filename}' ذخیره شد.")

    # حذف ماشین
    vehicle.destroy()
