function BoneScanEnhancement
% BoneScanEnhancement - 人体骨骼核扫描图像增强程序
% 该程序实现了针对灰度动态范围窄、噪声高的骨骼核扫描图像的增强
% 包含噪声抑制、Sobel边缘增强、拉普拉斯细节增强、对比度拉伸和直方图处理等功能

% 创建主界面
fig = figure('Name', '骨骼核扫描图像增强', 'Position', [100 100 1200 700], ...
    'NumberTitle', 'off', 'MenuBar', 'none', 'Resize', 'on');

% 创建面板
panelControl = uipanel(fig, 'Title', '控制面板', 'Position', [0.01 0.01 0.25 0.98]);
panelOriginal = uipanel(fig, 'Title', '原始图像', 'Position', [0.27 0.51 0.35 0.48]);
panelProcessed = uipanel(fig, 'Title', '处理后图像', 'Position', [0.63 0.51 0.35 0.48]);
panelSteps = uipanel(fig, 'Title', '处理步骤可视化', 'Position', [0.27 0.01 0.71 0.49]);

% 全局变量
originalImg = [];
processedImg = [];
noiseReducedImg = [];
sobelImg = [];
laplacianImg = [];
contrastStretchedImg = [];
histogramProcessedImg = [];

% 控制面板组件
uicontrol(panelControl, 'Style', 'pushbutton', 'String', '加载图像', ...
    'Position', [20 620 180 30], 'Callback', @loadImage);

% 噪声抑制参数
uicontrol(panelControl, 'Style', 'text', 'String', '噪声抑制', ...
    'Position', [20 580 180 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

filterTypeGroup = uibuttongroup(panelControl, 'Position', [20 530 180 50], ...
    'SelectionChangedFcn', @filterTypeChanged);
uicontrol(filterTypeGroup, 'Style', 'radiobutton', 'String', '高斯滤波', ...
    'Position', [10 25 80 20], 'Tag', 'gaussian');
uicontrol(filterTypeGroup, 'Style', 'radiobutton', 'String', '中值滤波', ...
    'Position', [100 25 80 20], 'Tag', 'median');

uicontrol(panelControl, 'Style', 'text', 'String', '滤波核大小:', ...
    'Position', [20 500 80 20], 'HorizontalAlignment', 'left');
kernelSizeSlider = uicontrol(panelControl, 'Style', 'slider', ...
    'Position', [100 500 80 20], 'Min', 3, 'Max', 9, 'Value', 3, ...
    'SliderStep', [0.25 0.25], 'Callback', @updateKernelSize);
kernelSizeText = uicontrol(panelControl, 'Style', 'text', 'String', '3x3', ...
    'Position', [180 500 40 20]);

uicontrol(panelControl, 'Style', 'text', 'String', '高斯σ值:', ...
    'Position', [20 470 80 20], 'HorizontalAlignment', 'left');
sigmaSlider = uicontrol(panelControl, 'Style', 'slider', ...
    'Position', [100 470 80 20], 'Min', 0.5, 'Max', 2.5, 'Value', 1, ...
    'SliderStep', [0.1 0.2], 'Callback', @updateSigma);
sigmaText = uicontrol(panelControl, 'Style', 'text', 'String', '1.0', ...
    'Position', [180 470 40 20]);

% Sobel边缘增强参数
uicontrol(panelControl, 'Style', 'text', 'String', 'Sobel边缘增强', ...
    'Position', [20 430 180 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

uicontrol(panelControl, 'Style', 'text', 'String', '增强强度:', ...
    'Position', [20 400 80 20], 'HorizontalAlignment', 'left');
sobelStrengthSlider = uicontrol(panelControl, 'Style', 'slider', ...
    'Position', [100 400 80 20], 'Min', 0, 'Max', 1, 'Value', 0.5, ...
    'SliderStep', [0.05 0.1], 'Callback', @updateSobelStrength);
sobelStrengthText = uicontrol(panelControl, 'Style', 'text', 'String', '0.5', ...
    'Position', [180 400 40 20]);

% 拉普拉斯细节增强参数
uicontrol(panelControl, 'Style', 'text', 'String', '拉普拉斯细节增强', ...
    'Position', [20 360 180 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

uicontrol(panelControl, 'Style', 'text', 'String', '增强强度:', ...
    'Position', [20 330 80 20], 'HorizontalAlignment', 'left');
laplacianStrengthSlider = uicontrol(panelControl, 'Style', 'slider', ...
    'Position', [100 330 80 20], 'Min', 0, 'Max', 1, 'Value', 0.3, ...
    'SliderStep', [0.05 0.1], 'Callback', @updateLaplacianStrength);
laplacianStrengthText = uicontrol(panelControl, 'Style', 'text', 'String', '0.3', ...
    'Position', [180 330 40 20]);

% 对比度拉伸参数
uicontrol(panelControl, 'Style', 'text', 'String', '对比度拉伸', ...
    'Position', [20 290 180 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

uicontrol(panelControl, 'Style', 'text', 'String', '下限阈值:', ...
    'Position', [20 260 80 20], 'HorizontalAlignment', 'left');
lowerLimitSlider = uicontrol(panelControl, 'Style', 'slider', ...
    'Position', [100 260 80 20], 'Min', 0, 'Max', 0.5, 'Value', 0.05, ...
    'SliderStep', [0.01 0.05], 'Callback', @updateContrastLimits);
lowerLimitText = uicontrol(panelControl, 'Style', 'text', 'String', '0.05', ...
    'Position', [180 260 40 20]);

uicontrol(panelControl, 'Style', 'text', 'String', '上限阈值:', ...
    'Position', [20 230 80 20], 'HorizontalAlignment', 'left');
upperLimitSlider = uicontrol(panelControl, 'Style', 'slider', ...
    'Position', [100 230 80 20], 'Min', 0.5, 'Max', 1, 'Value', 0.95, ...
    'SliderStep', [0.01 0.05], 'Callback', @updateContrastLimits);
upperLimitText = uicontrol(panelControl, 'Style', 'text', 'String', '0.95', ...
    'Position', [180 230 40 20]);

% 直方图处理参数
uicontrol(panelControl, 'Style', 'text', 'String', '直方图处理', ...
    'Position', [20 190 180 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');

histProcessingGroup = uibuttongroup(panelControl, 'Position', [20 140 180 50], ...
    'SelectionChangedFcn', @histProcessingChanged);
uicontrol(histProcessingGroup, 'Style', 'radiobutton', 'String', '无', ...
    'Position', [10 25 50 20], 'Tag', 'none');
uicontrol(histProcessingGroup, 'Style', 'radiobutton', 'String', '全局均衡化', ...
    'Position', [60 25 80 20], 'Tag', 'histeq');
uicontrol(histProcessingGroup, 'Style', 'radiobutton', 'String', 'CLAHE', ...
    'Position', [140 25 50 20], 'Tag', 'clahe');

uicontrol(panelControl, 'Style', 'text', 'String', 'CLAHE窗口大小:', ...
    'Position', [20 110 100 20], 'HorizontalAlignment', 'left');
claheWindowSlider = uicontrol(panelControl, 'Style', 'slider', ...
    'Position', [120 110 60 20], 'Min', 4, 'Max', 16, 'Value', 8, ...
    'SliderStep', [0.1 0.2], 'Callback', @updateClaheWindow);
claheWindowText = uicontrol(panelControl, 'Style', 'text', 'String', '8', ...
    'Position', [180 110 40 20]);

uicontrol(panelControl, 'Style', 'text', 'String', 'CLAHE对比度限制:', ...
    'Position', [20 80 100 20], 'HorizontalAlignment', 'left');
claheClipLimitSlider = uicontrol(panelControl, 'Style', 'slider', ...
    'Position', [120 80 60 20], 'Min', 0.01, 'Max', 0.1, 'Value', 0.02, ...
    'SliderStep', [0.01 0.02], 'Callback', @updateClaheClipLimit);
claheClipLimitText = uicontrol(panelControl, 'Style', 'text', 'String', '0.02', ...
    'Position', [180 80 40 20]);

% 处理按钮
uicontrol(panelControl, 'Style', 'pushbutton', 'String', '处理图像', ...
    'Position', [20 40 180 30], 'Callback', @processImage);

% 保存按钮
uicontrol(panelControl, 'Style', 'pushbutton', 'String', '保存结果', ...
    'Position', [20 10 180 20], 'Callback', @saveResults);

% 回调函数
    function loadImage(~, ~)
        [filename, pathname] = uigetfile({'*.jpg;*.tif;*.png;*.gif;*.bmp', '图像文件 (*.jpg, *.tif, *.png, *.gif, *.bmp)'}, '选择骨骼核扫描图像');
        if isequal(filename, 0) || isequal(pathname, 0)
            return;
        end
        
        % 读取图像
        originalImg = imread(fullfile(pathname, filename));
        
        % 如果是彩色图像，转换为灰度图
        if size(originalImg, 3) == 3
            originalImg = rgb2gray(originalImg);
        end
        
        % 显示原始图像
        axes('Parent', panelOriginal);
        imshow(originalImg);
        title('原始图像');
        
        % 清空处理结果
        processedImg = [];
        axes('Parent', panelProcessed);
        cla;
        title('处理后图像');
        
        % 清空处理步骤
        axes('Parent', panelSteps);
        cla;
        title('处理步骤可视化');
    end

    function filterTypeChanged(~, event)
        % 根据选择的滤波类型更新UI
        if strcmp(event.NewValue.Tag, 'gaussian')
            sigmaSlider.Enable = 'on';
            sigmaText.Enable = 'on';
        else
            sigmaSlider.Enable = 'off';
            sigmaText.Enable = 'off';
        end
    end

    function updateKernelSize(hObject, ~)
        % 更新滤波核大小
        value = round(get(hObject, 'Value'));
        % 确保是奇数
        if mod(value, 2) == 0
            value = value + 1;
        end
        set(hObject, 'Value', value);
        set(kernelSizeText, 'String', [num2str(value) 'x' num2str(value)]);
    end

    function updateSigma(hObject, ~)
        % 更新高斯滤波的σ值
        value = get(hObject, 'Value');
        set(sigmaText, 'String', sprintf('%.1f', value));
    end

    function updateSobelStrength(hObject, ~)
        % 更新Sobel增强强度
        value = get(hObject, 'Value');
        set(sobelStrengthText, 'String', sprintf('%.2f', value));
    end

    function updateLaplacianStrength(hObject, ~)
        % 更新拉普拉斯增强强度
        value = get(hObject, 'Value');
        set(laplacianStrengthText, 'String', sprintf('%.2f', value));
    end

    function updateContrastLimits(hObject, ~)
        % 更新对比度拉伸限制
        if hObject == lowerLimitSlider
            value = get(hObject, 'Value');
            set(lowerLimitText, 'String', sprintf('%.2f', value));
            
            % 确保下限小于上限
            upperValue = get(upperLimitSlider, 'Value');
            if value >= upperValue
                set(upperLimitSlider, 'Value', min(1, value + 0.1));
                set(upperLimitText, 'String', sprintf('%.2f', min(1, value + 0.1)));
            end
        else
            value = get(hObject, 'Value');
            set(upperLimitText, 'String', sprintf('%.2f', value));
            
            % 确保上限大于下限
            lowerValue = get(lowerLimitSlider, 'Value');
            if value <= lowerValue
                set(lowerLimitSlider, 'Value', max(0, value - 0.1));
                set(lowerLimitText, 'String', sprintf('%.2f', max(0, value - 0.1)));
            end
        end
    end

    function histProcessingChanged(~, event)
        % 根据选择的直方图处理方法更新UI
        if strcmp(event.NewValue.Tag, 'clahe')
            claheWindowSlider.Enable = 'on';
            claheWindowText.Enable = 'on';
            claheClipLimitSlider.Enable = 'on';
            claheClipLimitText.Enable = 'on';
        else
            claheWindowSlider.Enable = 'off';
            claheWindowText.Enable = 'off';
            claheClipLimitSlider.Enable = 'off';
            claheClipLimitText.Enable = 'off';
        end
    end

    function updateClaheWindow(hObject, ~)
        % 更新CLAHE窗口大小
        value = round(get(hObject, 'Value'));
        set(hObject, 'Value', value);
        set(claheWindowText, 'String', num2str(value));
    end

    function updateClaheClipLimit(hObject, ~)
        % 更新CLAHE对比度限制
        value = get(hObject, 'Value');
        set(claheClipLimitText, 'String', sprintf('%.2f', value));
    end

    function processImage(~, ~)
        % 检查是否已加载图像
        if isempty(originalImg)
            errordlg('请先加载图像！', '错误');
            return;
        end
        
        % 获取参数
        filterType = get(get(filterTypeGroup, 'SelectedObject'), 'Tag');
        kernelSize = round(get(kernelSizeSlider, 'Value'));
        sigma = get(sigmaSlider, 'Value');
        sobelStrength = get(sobelStrengthSlider, 'Value');
        laplacianStrength = get(laplacianStrengthSlider, 'Value');
        lowerLimit = get(lowerLimitSlider, 'Value');
        upperLimit = get(upperLimitSlider, 'Value');
        histProcessing = get(get(histProcessingGroup, 'SelectedObject'), 'Tag');
        claheWindow = round(get(claheWindowSlider, 'Value'));
        claheClipLimit = get(claheClipLimitSlider, 'Value');
        
        % 转换为双精度以便处理
        img = im2double(originalImg);
        
        % 步骤1：噪声抑制
        if strcmp(filterType, 'gaussian')
            noiseReducedImg = imgaussfilt(img, sigma, 'FilterSize', [kernelSize kernelSize]);
        else % 中值滤波
            noiseReducedImg = medfilt2(img, [kernelSize kernelSize]);
        end
        
        % 步骤2：Sobel边缘增强
        [Gx, Gy] = imgradientxy(noiseReducedImg, 'sobel');
        G = sqrt(Gx.^2 + Gy.^2);
        % 归一化梯度图像
        G = G / max(G(:));
        % 将Sobel梯度与原图融合
        sobelImg = noiseReducedImg + sobelStrength * G;
        % 确保值在[0,1]范围内
        sobelImg = min(max(sobelImg, 0), 1);
        
        % 步骤3：拉普拉斯细节增强
        laplacianKernel = [0 1 0; 1 -4 1; 0 1 0];
        laplacianResult = conv2(sobelImg, laplacianKernel, 'same');
        % 将拉普拉斯结果与Sobel增强图像融合
        laplacianImg = sobelImg - laplacianStrength * laplacianResult;
        % 确保值在[0,1]范围内
        laplacianImg = min(max(laplacianImg, 0), 1);
        
        % 步骤4：对比度拉伸
        contrastStretchedImg = imadjust(laplacianImg, [lowerLimit upperLimit], [0 1]);
        
        % 步骤5：直方图处理
        if strcmp(histProcessing, 'histeq')
            histogramProcessedImg = histeq(contrastStretchedImg);
        elseif strcmp(histProcessing, 'clahe')
            histogramProcessedImg = adapthisteq(contrastStretchedImg, ...
                'NumTiles', [claheWindow claheWindow], ...
                'ClipLimit', claheClipLimit);
        else
            histogramProcessedImg = contrastStretchedImg;
        end
        
        % 最终处理结果
        processedImg = histogramProcessedImg;
        
        % 显示处理后图像
        axes('Parent', panelProcessed);
        imshow(processedImg);
        title('处理后图像');
        
        % 显示处理步骤
        axes('Parent', panelSteps);
        subplot(2, 3, 1, 'Parent', panelSteps);
        imshow(originalImg);
        title('原始图像');
        
        subplot(2, 3, 2, 'Parent', panelSteps);
        imshow(noiseReducedImg);
        title('噪声抑制');
        
        subplot(2, 3, 3, 'Parent', panelSteps);
        imshow(sobelImg);
        title('Sobel边缘增强');
        
        subplot(2, 3, 4, 'Parent', panelSteps);
        imshow(laplacianImg);
        title('拉普拉斯细节增强');
        
        subplot(2, 3, 5, 'Parent', panelSteps);
        imshow(contrastStretchedImg);
        title('对比度拉伸');
        
        subplot(2, 3, 6, 'Parent', panelSteps);
        imshow(processedImg);
        title('最终结果');
    end

    function saveResults(~, ~)
        % 检查是否已处理图像
        if isempty(processedImg)
            errordlg('请先处理图像！', '错误');
            return;
        end
        
        % 保存处理后的图像
        [filename, pathname] = uiputfile({'*.jpg;*.tif;*.png;*.bmp', '图像文件 (*.jpg, *.tif, *.png, *.bmp)'}, '保存处理后的图像');
        if isequal(filename, 0) || isequal(pathname, 0)
            return;
        end
        
        % 保存图像
        imwrite(processedImg, fullfile(pathname, filename));
        msgbox('图像保存成功！', '提示');
    end
end