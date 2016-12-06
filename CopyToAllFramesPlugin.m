classdef CopyToAllFramesPlugin < plugins.DENSEanalysisPlugin
    % CopyToAllFramesPlugin - A DENSEanalysis plugin
    %
    %   A plugin for copying one contour to all frames
    %
    % Copyright (c) 2016, Cardiac Imaging Technology Lab

    properties
        origcback   % Original callback
    end

    methods
        function validate(~, data, varargin)
            % validate - Check if the plugin can run.
            %
            %   Performs validation to ensure that the state of the program
            %   is correct to be able to run the plugin.
            %
            % USAGE:
            %   CopyToAllFramesPlugin.validate(data)
            %
            % INPUTS:
            %   data:   Object, DENSEdata object containing all underlying
            %           data from the DENSEanalysis program.

            % Assert that image data base been loaded
            assert(~isempty(data.seq), ...
                'You must load imaging data into DENSEanalysis first.')
        end

        function h = uimenu(self, parent, callback, varargin)
            % Find the parent object
            hfig = ancestor(parent, 'figure');

            data = guidata(hfig);

            % Parent menu (the ROI tool menu)
            parent = data.hdense.hroi.hmenu;

            self.origcback = callback;

            % Add the menu item to this menu
            h = uimenu('Parent', parent, ...
                       'Label', 'Copy to All Frames', ...
                       'Callback', @(s,e)self.callback(s), ...
                       'UserData', 90, ...
                       'Tag', class(self));

            % Make sure that it appears above the motion guided
            % segmentation plugin items
            setappdata(h, 'Priority', 90);
        end

        function callback(self, src)
            % callback - Custom uimenu callback
            %
            %   This ensures that we pass the proper parameter to the run
            %   method when the plugin is launched from the menu.

            hfig = ancestor(src, 'figure');
            data = guidata(hfig);

            % Call the normal callback and add our custom parameters
            feval(self.origcback, src, [], ...
                'ROIIndex', data.hdense.ROIIndex, ...
                'Frame', data.hdense.Frame);
        end

        function run(~, data, varargin)
            % run - Method executed when user selects the plugin
            %
            % USAGE:
            %   CopyToAllFramesPlugin.run(data)
            %
            % INPUTS:
            %   data:   Object, DENSEdata object containing all underlying
            %           data from the DENSEanalysis program.

            ip = inputParser();
            ip.addParamValue('ROIIndex', 1, @(x)isscalar(x) && x > 0);
            ip.addParamValue('Frame', 1, @(x)isscalar(x) && x > 0);
            ip.parse(varargin{:});

            inputs = ip.Results;

            ridx = inputs.ROIIndex;
            frame = inputs.Frame;

            roi = data.roi(inputs.ROIIndex);
            nFrames = size(roi.Position, 1);

            % Now we want to perform the actual action
            currentROI = struct(...
                'Position', {roi.Position(frame,:)}, ...
                'IsClosed', {roi.IsClosed(frame,:)}, ...
                'IsCorner', {roi.IsCorner(frame,:)}, ...
                'IsCurved', {roi.IsCurved(frame,:)});

            for k = 1:nFrames
                data.updateROI(ridx, k, currentROI);
            end
        end
    end
end
