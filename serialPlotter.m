classdef serialPlotter < handle
    
    properties (Access = private)
        dataMatrix
        i
        formatString
        serialObject
        plots
        scalers
        zeroSeen
    end
    
    methods (Access = private)
        % Callback method when data is received from serial input.
        function dataReceivedCallBack(obj, ~, ~)
            try
            % Read a line from the serial input. 
            line = fgetl(obj.serialObject);
            % Read the value into a cell.
            dataCell = textscan(line, obj.formatString, 'Delimiter', ',');
            if (((dataCell{1} ~= 0) && obj.zeroSeen) || dataCell {1} == 0)
                obj.zeroSeen = true;
                % Translate the cell into the data matrix.
                obj.dataMatrix(obj.i, :) = cellfun(@double, dataCell) .* obj.scalers;
                obj.i = obj.i + 1;

                % Plot the data from the cell.
                for j = 1:length(obj.plots)
                    set(obj.plots(j), ...
                    'xdata', obj.dataMatrix(1:obj.i - 1, 1), ...
                    'ydata', obj.dataMatrix(1:obj.i - 1, j + 1));
                end
                % Command a draw immediately.
                drawnow;
            end
            catch
                fclose(obj.serialObj);
            end
        end
    end
    
    methods (Access = public)
        %Constructor method for the serialPlotter
        function obj = serialPlotter(portName, baudRate, formatString, plotTitles, plotLabels, scalers)
            try 
                % Initialize the format string used to parse incoming serial data.
                obj.formatString = formatString;

                % Create a new serial object.
                obj.serialObject = serial(portName, 'BaudRate', baudRate, 'DataBits', 8);
                % Assign a callback function to run when information is read.
                obj.serialObject.BytesAvailableFcnMode = 'terminator';
                obj.serialObject.BytesAvailableFcn = @obj.dataReceivedCallBack;

                % Initialize the data matrix.
                % Number of columns is given by the number of format arguments
                % that are expected.
                numCols = length(regexp(formatString, '%[a-z|A-Z]'));
                % Number of rows is given by estimating that 1000 transmissions
                % per second occurs for 30 seconds.
                numRows = 30 * 10000;
                % Now we initialize the matrix.
                obj.dataMatrix = zeros(numRows, numCols);
                % Initialize its index to one. 
                obj.i = 1;

                % Create plots
                % The first argument is used as the x-axis, so there is 1
                % less window than there are formatting string arguments.
                numWindows = numCols - 1;
                for i = 1:numWindows
                    figure;
                    obj.plots(i) = plot(1,1);
                    if(exist('plotTitles','var')) 
                        %title(plotTitles{i}); % Causes real time plotting
                        %to be very slow for some reason!
                    end
                    if(exist('plotLabels', 'var'))
                        xlabel(plotLabels{1});
                        ylabel(plotLabels{i + 1});
                    end
                end
                
                % Store the scalers
                if(exist('scalers', 'var'))
                    obj.scalers = scalers;
                else
                    obj.scalers = ones(1:numCols);
                end
                % Open the serial port.
                fopen(obj.serialObject);
                % Send the reset byte.
                fwrite(obj.serialObject, uint8(' '), 'char');
                obj.zeroSeen = false;
            catch ME
                fclose(obj.serialObject);
                rethrow(ME);
            end
        end
        
        %Destructor method for the serialPlotter
        function delete(obj)
            fclose(obj.serialObject);
        end
        
        % Allows the user to get a copy of the data matrix.
        function dataMatrix = getData(obj)
            dataMatrix = obj.dataMatrix(1:obj.i - 1, :);
        end
        
    end
    
end

