classdef BluetoothPlotter < handle
    
    properties (Access = private)
        dataMatrix
        i
        %Whether it is the first time a line is being read. If so, perform
        %initialization.
        isFirstTime
        bluetoothObj
        plots
        zeroSeen
        plotLabels
        plotTitles
        plotTimer
        refreshTimer
    end
    
    methods (Access = private)
         % Helper function which does nothing.
        function NOP(varargins)
        end
        
        % Callback method when data is received from serial input.
        function dataReceivedCallBack(this, ~, ~)
            try

            % If it is the first time we're reading, then we initialize the
            % data matrix and plots.
            if(this.isFirstTime)
                this.isFirstTime = false;
                % Discard the first line, as it tends to be incomplete.
                fgetl(this.bluetoothObj);
                % Start processing the second line.
                line = fgetl(this.bluetoothObj);
                % Read the value into a cell.
                % dataCell = textscan(line, obj.formatString, 'Delimiter', ',');
                dataCell = strsplit(line, {',',' '});
                dataArray = cellfun(@str2num, dataCell);
                % Number of columns is the number of data elements read.
                numCols = length(dataArray);
                 % Number of rows is given by estimating that 100 transmissions
                % per second occurs for 30 seconds.
                numRows = 30 * 100;
                % Now we initialize the matrix.
                this.dataMatrix = zeros(numRows, numCols);
                % Initialize its index to one. 
                this.i = 1;
                % Create plots
                % The first argument is used as the x-axis, so there is 1
                % less window than there are formatting string arguments.
                numWindows = numCols - 1;
                 % Initialize the plot tiles and plot labels to empty
                 % cells. 
                titleConcatLen = numWindows - length(this.plotTitles);
                if(titleConcatLen > 0)
                    stringCells = cell(1, titleConcatLen);
                    stringCells(:) = {' '};
                    this.plotTitles = [this.plotTitles, stringCells];
                end
                labelConcatLen = numCols - length(this.plotLabels);
                if(labelConcatLen > 0)
                    stringCells = cell(1, labelConcatLen);
                    stringCells(:) = {' '};
                    this.plotLabels = [this.plotLabels, stringCells];
                end

                for j = 1:numWindows
                    figure;
                    this.plots(j) = plot(1,1);
                    title(this.plotTitles{j}); % Causes real time plotting
                    %to be very slow for some reason!
                    xlabel(this.plotLabels{1});
                    ylabel(this.plotLabels{j + 1});
                end
                this.refreshTimer = tic;
            else
                 % Read a line from the serial input. 
                line = fgetl(this.bluetoothObj);
                % disp(line);


                % Read the value into a cell.
                % dataCell = textscan(line, obj.formatString, 'Delimiter', ',');
                dataCell = strsplit(line, {',',' '});
                dataArray = cellfun(@str2num, dataCell);

                % Translate the cell into the data matrix.
                this.dataMatrix(this.i, :) = dataArray;
                
                if(toc(this.refreshTimer) > 0.033)
                    % Plot the data from the cell.
                    for j = 1:length(this.plots)
                        set(this.plots(j), ...
                        'xdata', this.dataMatrix(1:this.i, 1), ...
                        'ydata', this.dataMatrix(1:this.i, j + 1));
                    end
                    % Command a draw immediately.
                    drawnow;
                    this.refreshTimer = tic;
                end
                this.i = this.i + 1;
            %end
            end
            catch ME
                fclose(this.bluetoothObj);
                rethrow(ME);
            end
        end
    end
    
    methods (Access = public)
        %Constructor method for the serialPlotter
        function this = BluetoothPlotter(deviceName)
                % Create a new serial object
                this.bluetoothObj = Bluetooth(deviceName, 1);
                this.bluetoothObj.BytesAvailableFcnMode = 'terminator';
                this.bluetoothObj.BytesAvailableFcn = '';
                % Initialize the plot titles and plot labels.
                this.plotTitles = cell(1,1);
                this.plotLabels = cell(1,1);
        end
        
        %Destructor method for the serialPlotter
        function delete(this)
            this.bluetoothObj.BytesAvailableFcn = @NOP;
            fclose(this.bluetoothObj);
        end
        
        %Open the connection and begin plotting.
        function beginPlotting(this, plotTime)
            this.isFirstTime = true;
            this.bluetoothObj.BytesAvailableFcn = @this.dataReceivedCallBack;
            fopen(this.bluetoothObj);
            fwrite(this.bluetoothObj, uint8(' '), 'char');
            this.zeroSeen = true;
            this.plotTimer = timer( ...
                'ExecutionMode', 'singleShot', ...
                'StartDelay', plotTime, ...
                'TimerFcn', @this.stopPlotting);
            start(this.plotTimer);
        end
        
        function stopPlotting(this , ~, ~)
            % this.bluetoothObj.BytesAvailableFcn = '';
            fclose(this.bluetoothObj);
        end
        
        % Set the titles for each of the plots.
        function setTitles(this, plotTitles)
             this.plotTitles = plotTitles;
        end
        
        % Set the axis labels for each of the plots.
        function setAxisLabels(this, axisLabels)
             this.plotLabels = axisLabels;
        end
        
        % Allows the user to get a copy of the data matrix.
        function dataMatrix = getData(this)
            dataMatrix = this.dataMatrix(1:this.i - 1, :);
        end
        
    end
    
end

