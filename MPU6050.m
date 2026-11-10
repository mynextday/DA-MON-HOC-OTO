function mo_phong_goc_quay_CAN()
    f = figure('Name','Mô phỏng vô lăng - Truyền CAN','Position',[200 200 750 550]);

    % Slider điều khiển trực tiếp góc quay
    uicontrol('Style','text','Position',[250 480 200 20],'String','Góc quay thực tế θ (°)', 'FontWeight','bold');
    slider = uicontrol('Style','slider','Min',-900,'Max',900,'Value',0,...
        'SliderStep',[0.0001 0.001],...
        'Position',[150 450 400 25],'Callback',@sliderCallback);
    angle_label = uicontrol('Style','text','Position',[310 420 120 20],'String','θ = 0.00°','FontSize',10);

    % Ô nhập trực tiếp giá trị góc
    uicontrol('Style','text','Position',[570 480 100 20],'String','Nhập góc (°):','FontWeight','bold');
    angle_input = uicontrol('Style','edit','Position',[580 450 60 25],'String','0.00','Callback',@manualInput);

    % Hiển thị LCD
    uicontrol('Style','text','Position',[300 390 100 20],'String','LCD Display','FontWeight','bold');
    lcd_display = uicontrol('Style','text','Position',[270 360 160 20],'String','Góc quay: 0.00°',...
        'FontSize',10,'BackgroundColor','black','ForegroundColor','green');

    % Hiển thị góc lớn nhất và hành trình
    info_max_display = uicontrol('Style','text','Position',[240 330 220 20],...
        'String','Max trái: 0.00° | Max phải: 0.00°', 'FontSize',9);
    info_total_display = uicontrol('Style','text','Position',[250 310 200 20],...
        'String','Tổng hành trình: 0.00°', 'FontSize',9);

    % Nút trả lái về 0°
    uicontrol('Style','pushbutton','Position',[290 270 120 30],'String','Trả lái về 0°',...
        'FontSize',10,'Callback',@resetTheta);

    % Vùng vẽ đồ thị
    ax = axes('Parent',f,'Position',[0.1 0.1 0.8 0.35]);
    grid on;
    xlabel('Thời gian (s)');
    ylabel('Góc quay (°)');
    title('Góc quay vô lăng từ MPU6050');
    ylim([-1000 1000]);

    % Biến mô phỏng
    dt = 0.05;
    t = 0;
    theta_log = [];
    time_log = [];
    max_left = 0;
    max_right = 0;
    total_travel = 0;
    prev_theta = 0;

    % Timer
    timer_obj = timer('ExecutionMode','fixedSpacing','Period',dt,'TimerFcn',@updatePlot);
    start(timer_obj);

    % Slider callback
    function sliderCallback(src, ~)
        val = get(src, 'Value');
        val = round(val*100)/100; % Làm tròn 0.01 độ
        set(angle_label, 'String', sprintf('θ = %.2f°', val));
        set(angle_input, 'String', sprintf('%.2f', val)); % cập nhật ô nhập
        set(slider, 'Value', val); % giữ slider tại giá trị làm tròn
    end

    % Ô nhập tay callback
    function manualInput(src, ~)
        val = str2double(get(src,'String'));
        if isnan(val) || val < -900 || val > 900
            errordlg('Giá trị ngoài phạm vi -900 đến +900','Lỗi');
        else
            val = round(val*100)/100;
            set(slider, 'Value', val);
            sliderCallback(slider);
        end
    end

    % Cập nhật mô phỏng
    function updatePlot(~, ~)
        theta = get(slider, 'Value');
        theta = round(theta*100)/100; % Làm tròn 0.01 độ
        t = t + dt;
        theta_log(end+1) = theta;
        time_log(end+1) = t;

        % CAN mô phỏng (truyền và nhận)
        received_data = theta;

        % Hiển thị LCD
        set(lcd_display, 'String', sprintf('Góc quay: %.2f°', received_data));

        % Cập nhật max trái/phải
        if theta > max_right
            max_right = theta;
        end
        if theta < max_left
            max_left = theta;
        end

        % Tính tổng hành trình
        total_travel = total_travel + abs(theta - prev_theta);
        prev_theta = theta;

        set(info_max_display, 'String', sprintf('Max trái: %.2f° | Max phải: %.2f°', max_left, max_right));
        set(info_total_display, 'String', sprintf('Tổng hành trình: %.2f°', total_travel));

        % Vẽ đồ thị
        plot(ax, time_log, theta_log, 'b', 'LineWidth', 2);
        xlim(ax, [max(0, t-10), t+1]);
    end

    % Nút trả lái
    function resetTheta(~, ~)
        set(slider, 'Value', 0);
        set(angle_label, 'String', 'θ = 0.00°');
        set(angle_input, 'String', '0.00');
    end

    % Đóng GUI
    f.CloseRequestFcn = @(src,~) closeGUI();
    function closeGUI()
        stop(timer_obj);
        delete(timer_obj);
        delete(f);
    end
end
