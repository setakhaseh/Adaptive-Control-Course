clc; clear;

% ===== پارامترهای واقعی =====
A = [0 1 0;
     0.01 0 1;
     0    0 0];     % a11 = 0 , a21 = 0.01 , a31 = 0
B = [1; 0; 2];       % b11 = 1 , b12 = 0 , b13 = 2
C = [1 0 0];

% ===== تنظیمات شبیه‌سازی =====
T = 200;
n = 3;
x = zeros(n, T);
y = zeros(1, T);
u = randn(1, T);   % ورودی تصادفی

for t = 2:T
    x(:,t) = A * x(:,t-1) + B * u(t-1);
    y(t) = C * x(:,t);
end

% ===== الگوریتم Projection =====
theta_hat = zeros(6,1);           % [a11; a21; a31; b11; b12; b13]
theta_history = zeros(6, T);
threshold = 10;                   % کران φ برای اعمال Projection

for t = 4:T
    phi = [y(t-1); y(t-2); y(t-3); u(t-1); u(t-2); u(t-3)];
    
    if norm(phi) <= threshold     % شرط Projection
        y_hat = phi' * theta_hat;
        e = y(t) - y_hat;
        
        denom = phi' * phi + 1e-6;
        theta_hat = theta_hat + (phi * e) / denom;
    end

    theta_history(:,t) = theta_hat;
end

% ===== نمایش نتایج نهایی =====
disp('تخمین نهایی پارامترها با Projection:')
disp('theta_hat = [a11; a21; a31; b11; b12; b13]')
disp(theta_hat)

% ===== رسم نمودار تخمین پارامترها =====
labels = {'a11','a21','a31','b11','b12','b13'};
theta_real = [0; 0.01; 0; 1; 0; 2];

figure;
for i = 1:6
    subplot(3,2,i)
    plot(theta_history(i,:), 'b', 'LineWidth', 1.4); hold on
    yline(theta_real(i), 'k--', 'LineWidth', 1.2);
    xlabel('Time step'); ylabel(labels{i})
    legend('Estimated','True'); grid on
end
sgtitle('تخمین پارامترها با الگوریتم Projection')
