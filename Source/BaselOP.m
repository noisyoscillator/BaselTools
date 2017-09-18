classdef (Sealed) BaselOP < handle
    %% Properties: Instance
    properties (Access = private)
        Handles
        Initialized
        Modifiers
        Transition
        Year
    end
    
    %% Constructor
    methods (Access = public)
        function this = BaselOP()
            fig = findall(0,'Tag','BaselOP');
            
            if (~isempty(fig))
                if (isvalid(fig))
                    figure(fig);
                    return;
                else
                    delete(fig);
                end
            end
            
            warning('off','all');
            
            com.mathworks.mwswing.MJUtilities.initJIDE();
            javaaddpath(fullfile(pwd(),'BaselTools.jar'));
            
            this.Initialized = false;
            this.Transition = false;
            this.Year = year(now());
            
            gui = struct();
            gui.gui_Name = mfilename;
            gui.gui_Singleton = false;
            gui.gui_Callback = [];
            gui.gui_OpeningFcn = @this.Form_Load;
            gui.gui_OutputFcn = @this.Form_Output;
            gui.gui_LayoutFcn = [];
            
            gui_mainfcn(gui);
        end
    end
    
    %% Destructor
    methods (Access = private)
        function delete(this)
            if (~isempty(this.Handles))
                this.Handles.BaselOP.CloseRequestFcn = '';
                delete(this.Handles.BaselOP);
            end
            
            this.Handles = [];
            this.Initialized = [];
            this.Modifiers = [];
            this.Transition = [];
            this.Year = [];
        end
    end
    
    %% Methods: Events
    methods (Access = private)
        function Form_Close(this,obj,evd) %#ok<INUSD>
            delete(this);
        end
        
        function Form_KeyModifiers(this,obj,evd) %#ok<INUSL>
            this.Modifiers = evd.Modifier;
        end
        
        function Form_Load(this,obj,evd,han,varargin) %#ok<INUSL>
            obj.CloseRequestFcn = @this.Form_Close;
            obj.WindowKeyPressFcn = @this.Form_KeyModifiers;
            obj.WindowKeyReleaseFcn = @this.Form_KeyModifiers;
            
            han.LossButtonClear.Callback = @this.LossButtonClear_Clicked;
            han.LossButtonLoad.Callback = @this.LossButtonLoad_Clicked;
            han.LossButtonThresholdMinus.Callback = @this.LossButtonThreshold_Clicked;
            han.LossButtonThresholdPlus.Callback = @this.LossButtonThreshold_Clicked;
            han.LossButtonYearMinus.Callback = @this.LossButtonYear_Clicked;
            han.LossButtonYearPlus.Callback = @this.LossButtonYear_Clicked;
            han.LossCheckboxTransition.Callback = @this.LossCheckboxTransition_CheckedChanged;
            han.CapitalButtonDefault.Callback = @this.CapitalButtonDefault_Clicked;
            han.CapitalButtonExport.Callback = @this.CapitalButtonExport_Clicked;
            han.CapitalButtonFile.Callback = @this.CapitalButtonFile_Clicked;
            han.CapitalCheckboxCompact.Callback = @this.CapitalCheckboxCompact_Clicked;
            han.CapitalGroupApproach.SelectionChangeFcn = @this.CapitalGroupApproach_SelectionChanged;
            
            han.TabGroup = uitabgroup('Parent',obj);
            han.TabGroup.Units = 'pixels';
            han.TabGroup.Position = [2 1 1024 768];
            han.IntroductionTab = uitab('Parent',han.TabGroup);
            han.IntroductionTab.Tag = 'IntroductionTab';
            han.IntroductionTab.Title = 'Introduction';
            han.IntroductionPanel.Parent = han.IntroductionTab;
            han.BusinessTab = uitab('Parent',han.TabGroup);
            han.BusinessTab.Tag = 'BusinessTab';
            han.BusinessTab.Title = 'Business Indicator Component';
            han.BusinessPanel.Parent = han.BusinessTab;
            han.LossTab = uitab('Parent',han.TabGroup);
            han.LossTab.Tag = 'LossTab';
            han.LossTab.Title = 'Loss Component';
            han.LossPanel.Parent = han.LossTab;
            han.CapitalTab = uitab('Parent',han.TabGroup);
            han.CapitalTab.Tag = 'CapitalTab';
            han.CapitalTab.Title = 'Capital Requirement';
            han.CapitalPanel.Parent = han.CapitalTab;
            
            guidata(obj,han);
            this.Handles = guidata(obj);
            
            uistack(han.Blank,'top');
            
            scr = groot;
            scr.Units = 'pixels';
            scr_siz = scr.ScreenSize;
            obj.Position = [((scr_siz(3) - 1024) / 2) ((scr_siz(4) - 768) / 2) 1024 768];
        end
        
        function varargout = Form_Output(this,obj,evd,han) %#ok<INUSD>
            varargout = cell(0,0);
            
            import('java.awt.*');
            
            bar = waitbar(0,'Initializing...','CloseRequestFcn','','WindowStyle','modal');
            frm = Frame.getFrames();
            frm(end).setAlwaysOnTop(true);
            
            yea = this.Year - 10;
            
            tab_bus_data_col = this.Handles.BusinessTableData.ColumnName;
            tab_bus_data_col{2} = sprintf('Value %d',(this.Year - 3));
            tab_bus_data_col{3} = sprintf('Value %d',(this.Year - 2));
            tab_bus_data_col{4} = sprintf('Value %d',(this.Year - 1));
            
            tab_bus_data = cell(15,5);
            tab_bus_data([2:7 9:10 12:15],2:5) = {0};
            tab_bus_data(1:7,1) = {'Interest, Lease & Dividend Component' 'II' 'IE' 'IEA' 'LI' 'LE' 'DI'};
            tab_bus_data(8:10,1) = {'Financial Component' 'BB' 'TB'};
            tab_bus_data(11:15,1) = {'Services Component' 'FI' 'FE' 'OOI' 'OOE'};
            
            tab_bus_agg = cell(5,2);
            tab_bus_agg(:,1) = {'ILDC' 'FC' 'SC' 'UBI' 'BI'};
            tab_bus_agg(:,2) = {0};
            
            tab_bus_com = cell(5,3);
            tab_bus_com(:,1) = {'1' '2' '3' '4' '5'};
            tab_bus_com(:,2) = {'0 - 1bn' '1bn - 3bn' '3bn - 10bn' '10bn - 30bn' '30bn - INF'};
            tab_bus_com(:,3) = {0 '-' '-' '-' '-'};
            
            tab_capi_data_col = this.Handles.CapitalTableComparison.ColumnName;
            tab_capi_data_col{2} = sprintf('Value %d',(this.Year - 3));
            tab_capi_data_col{3} = sprintf('Value %d',(this.Year - 2));
            tab_capi_data_col{4} = sprintf('Value %d',(this.Year - 1));
            
            tab_capi_res = cell(5,2);
            tab_capi_res(:,1) = {'BIC' 'LC' 'ILM' 'K SMA' 'K BII'};
            tab_capi_res([1 4 5],2) = {0};
            tab_capi_res([2 3],2) = {'-'};
            
            tab_capi_com = cell(8,4);
            tab_capi_com(:,1) = {'AG' 'AM' 'CB' 'CF' 'PS' 'RBA' 'RBR' 'TS'};
            tab_capi_com(:,2:4) = {0};
            
            try
                uistack(this.Handles.Blank,'bottom');
                
                this.SetupBox(this.Handles.IntroductionBox);
                
                this.Handles.BusinessTableData.ColumnName = tab_bus_data_col;
                this.SetupTable(this.Handles.BusinessTableData, ...
                    'Data',       tab_bus_data, ...
                    'Callback',   @this.BusinessTableData_DataChanged, ...
                    'Editor',     {'EditorCurrency' 0 1e12 0}, ...
                    'Renderer',   {'RendererOpBusData'}, ...
                    'Selection',  [false false false], ...
                    'Table',      {'TableOpBusData'});
                this.SetupTable(this.Handles.BusinessTableResult, ...
                    'Data',       tab_bus_agg, ...
                    'Renderer',   {'RendererOpBusRslt'}, ...
                    'RowsHeight', 60, ...
                    'Selection',  [false false false]);
                this.SetupTable(this.Handles.BusinessTableComponent, ...
                    'Data',       tab_bus_com, ...
                    'Renderer',   {'RendererOpBusComp'}, ...
                    'RowsHeight', 60, ...
                    'Selection',  [false false false]);
                this.SetupBox(this.Handles.BusinessBox);
                
                this.Handles.LossTextboxYear.String = num2str(yea);
                this.Handles.LossTextboxYear.UserData = yea;
                this.SetupTable(this.Handles.LossTableDataset, ...
                    'RowHeaderWidth',    56, ...
                    'Selection',         [false false false], ...
                    'Sorting',           2, ...
                    'VerticalScrollbar', true);
                this.SetupTable(this.Handles.LossTableResult, ...
                    'RowsHeight',        75, ...
                    'Selection',         [false false false]);
                this.SetupBox(this.Handles.LossBox);
                
                this.SetupTable(this.Handles.CapitalTableResult, ...
                    'Data',       tab_capi_res, ...
                    'Renderer',   {'RendererOpCapRslt'}, ...
                    'RowsHeight', 60, ...
                    'Selection',  [false false false]);
                this.Handles.CapitalTableComparison.ColumnName = tab_capi_data_col;
                this.SetupTable(this.Handles.CapitalTableComparison, ...
                    'Data',       tab_capi_com, ...
                    'Callback',   @this.CapitalTableComparison_DataChanged, ...
                    'Editor',     {'EditorCurrency' -1e12 1e12 0}, ...
                    'Renderer',   {'RendererOpCapCmpr'}, ...
                    'RowsHeight', 37, ...
                    'Selection',  [false false false], ...
                    'Table',      {'TableOpCapCmpr'});
                this.SetupBox(this.Handles.CapitalBoxExport);
                this.Handles.CapitalTextboxFile.String = [' ' fullfile(pwd(),'Result.xlsx') ' '];
                this.SetupTextbox(this.Handles.CapitalTextboxFile);
                this.Handles.CapitalButtonExport.Enable = 'on';
                this.SetupBox(this.Handles.CapitalBoxInformation);
                
                this.Initialized = true;
            catch e
                delete(bar);
                
                err = ['The initialization process failed. The exception produced is: "' regexprep(strtrim(e.message),'[\n\r]+',' ') '".'];
                
                dlg = errordlg(err,'Error','modal');
                uiwait(dlg);
                
                delete(this);
                
                return;
            end
            
            waitbar(1,bar);
            delete(bar);
        end
        
        function BusinessTableData_DataChanged(this,obj,evd)
            if (~this.Initialized)
                return;
            end
            
            col = evd.getColumn();
            row = evd.getFirstRow();
            
            if ((col < 1) || (col > 3) || (row == 0) || (row == 7) || (row == 10))
                return;
            end
            
            val_t2 = obj.getValueAt(row,1);
            val_t1 = obj.getValueAt(row,2);
            val_t0 = obj.getValueAt(row,3);
            
            obj.setValueAt(mean([val_t2 val_t1 val_t0]),row,4);
            
            this.UpdateData();
        end
        
        function CapitalButtonDefault_Clicked(this,obj,evd) %#ok<INUSD>
            obj.Enable = 'off';
            
            this.Handles.CapitalTextboxFile.String = [' ' fullfile(pwd(),'Result.xlsx') ' '];
            this.Handles.CapitalCheckboxCompact.Value = 0;
            this.Handles.CapitalCheckboxStyles.Value = 1;
            this.Handles.CapitalCheckboxLoss.Value = 0;
            this.Handles.CapitalCheckboxComparison.Value = 0;
            
            obj.Enable = 'on';
        end
        
        function CapitalButtonExport_Clicked(this,obj,evd) %#ok<INUSD>
            obj.Enable = 'off';
            
            import('java.awt.*');
            
            bar = waitbar(0,'Expoting Data...','CloseRequestFcn','','WindowStyle','modal');
            frm = Frame.getFrames();
            frm(end).setAlwaysOnTop(true);
            
            file = strtrim(this.Handles.CapitalTextboxFile.String);
            err = this.ExportData(file);
            
            waitbar(1,bar);
            delete(bar);
            
            if (~isempty(err))
                dlg = errordlg(err,'Error','modal');
                uiwait(dlg);
            end
            
            obj.Enable = 'on';
        end
        
        function CapitalButtonFile_Clicked(this,obj,evd) %#ok<INUSD>
            obj.Enable = 'off';
            
            [name,path] = uiputfile({'*.xls;*.xlsx','Excel Spreadsheets (*.xls;*.xlsx)'},'Select Destination',pwd());
            
            if (name ~= 0)
                file = fullfile(path,name);
                
                if (~endsWith(file,'.xls') && ~endsWith(file,'.xlsx'))
                    file = [file '.xls'];
                end
                
                this.Handles.CapitalTextboxFile.String = [' ' file ' '];
            end
            
            obj.Enable = 'on';
        end
        
        function CapitalCheckboxCompact_Clicked(this,obj,evd) %#ok<INUSD>
            if (obj.Value == 0)
                jpan_cap_rslt = javaObjectEDT(findjobj(this.Handles.CapitalTableResult));
                jtab_cap_rslt = javaObjectEDT(jpan_cap_rslt.getViewport().getView());
                
                if (~ischar(jtab_cap_rslt.getValueAt(1,1)))
                    this.Handles.CapitalCheckboxLoss.Enable = 'on';
                end
            else
                this.Handles.CapitalCheckboxLoss.Value = 0;
                this.Handles.CapitalCheckboxLoss.Enable = 'off';
            end
        end
        
        function CapitalGroupApproach_SelectionChanged(this,obj,evd) %#ok<INUSL>
            this.UpdateComparison(evd.NewValue.String);
        end
        
        function CapitalTableComparison_DataChanged(this,obj,evd) %#ok<INUSL>
            if (~this.Initialized)
                return;
            end
            
            col = evd.getColumn();
            
            if (col < 1)
                return;
            end
            
            this.UpdateComparison();
        end
        
        function LossButtonClear_Clicked(this,obj,evd) %#ok<INUSD>
            obj.Enable = 'off';
            
            jpan_cap_rslt = javaObjectEDT(findjobj(this.Handles.CapitalTableResult));
            jtab_cap_rslt = javaObjectEDT(jpan_cap_rslt.getViewport().getView());
            jtab_cap_rslt.setValueAt('-',1,1);
            
            this.UpdateCapital();
            
            this.LossComponentEnable(true);
        end
        
        function LossButtonLoad_Clicked(this,obj,evd) %#ok<INUSD>
            obj.Enable = 'off';
            
            [name,path] = uigetfile({'*.xls;*.xlsx','Excel Spreadsheets (*.xls;*.xlsx)'},'Load Dataset',pwd());
            
            if (name == 0)
                obj.Enable = 'on';
                return;
            end
            
            import('java.awt.*');
            
            bar = waitbar(0,'Loading Dataset...','CloseRequestFcn','','WindowStyle','modal');
            frm = Frame.getFrames();
            frm(end).setAlwaysOnTop(true);
            
            file = fullfile(path,name);
            [data,err] = this.DatasetLoad(file);
            
            if (~isempty(err))
                delete(bar);
                
                dlg = errordlg(err,'Error','modal');
                uiwait(dlg);
                
                obj.Enable = 'on';
                
                return;
            end
            
            waitbar(0.25,bar,'Validating Dataset...');
            
            err = this.DatasetValidate(data);
            
            if (~isempty(err))
                delete(bar);
                
                dlg = errordlg(err,'Error','modal');
                uiwait(dlg);
                
                obj.Enable = 'on';
                
                return;
            end
            
            waitbar(0.50,bar,'Analyzing Dataset...');
            
            [data,err] = this.DatasetAnalyze(data);
            
            if (~isempty(err))
                delete(bar);
                
                dlg = errordlg(err,'Error','modal');
                uiwait(dlg);
                
                obj.Enable = 'on';
                
                return;
            end
            
            jpan_cap_rslt = javaObjectEDT(findjobj(this.Handles.CapitalTableResult));
            jtab_cap_rslt = javaObjectEDT(jpan_cap_rslt.getViewport().getView());
            jtab_cap_rslt.setValueAt(data.Variables{4,2},1,1);
            
            this.UpdateCapital();
            
            waitbar(0.75,bar,'Updating Interface...');
            
            this.LossComponentDisable(true);
            
            this.SetupTable(this.Handles.LossTableDataset, ...
                'Data',              data.Dataset, ...
                'Renderer',          {'RendererOpLossData' data.MaximumID data.MaximumLoss data.MaximumRecovery}, ...
                'RowHeaderWidth',    56, ...
                'Selection',         [false false false], ...
                'Sorting',           2, ...
                'VerticalScrollbar', true);
            this.SetupTable(this.Handles.LossTableResult, ...
                'Data',              data.Variables, ...
                'Renderer',          {'RendererOpLossRslt'}, ...
                'RowsHeight',        75, ...
                'Selection',         [false false false]);
            
            waitbar(1,bar);
            delete(bar);
        end
        
        function LossButtonThreshold_Clicked(this,obj,evd) %#ok<INUSD>
            obj.Enable = 'off';
            
            prev = this.Handles.LossTextboxThreshold.UserData;
            
            if ((numel(this.Modifiers) == 1) && strcmp(this.Modifiers{1},'control'))
                span = 1000;
            else
                span = 100;
            end
            
            if (this.Transition)
                lim = 20000;
            else
                lim = 10000;
            end
            
            if (strcmp(strrep(obj.Tag,'LossButtonThreshold',''),'Minus'))
                curr = prev - span;
                
                if (curr < 0)
                    curr = 0;
                end
            else
                curr = prev + span;
                
                if (curr > lim)
                    curr = lim;
                end
            end
            
            this.Handles.LossTextboxThreshold.String = num2str(curr);
            this.Handles.LossTextboxThreshold.UserData = curr;
            
            switch (curr)
                case 0
                    this.Handles.LossButtonThresholdMinus.Enable = 'off';
                    this.Handles.LossButtonThresholdPlus.Enable = 'on';
                case lim
                    this.Handles.LossButtonThresholdMinus.Enable = 'on';
                    this.Handles.LossButtonThresholdPlus.Enable = 'off';
                otherwise
                    this.Handles.LossButtonThresholdMinus.Enable = 'on';
                    this.Handles.LossButtonThresholdPlus.Enable = 'on';
            end
        end
        
        function LossButtonYear_Clicked(this,obj,evd) %#ok<INUSD>
            obj.Enable = 'off';
            
            prev = this.Handles.LossTextboxYear.UserData;
            lim_beg = this.Year - 10;
            lim_end = this.Year - 5;
            
            if (strcmp(strrep(obj.Tag,'LossButtonYear',''),'Minus'))
                curr = prev - 1;
                
                if (curr < lim_beg)
                    curr = lim_beg;
                end
            else
                curr = prev + 1;
                
                if (curr > lim_end)
                    curr = lim_end;
                end
            end
            
            this.Handles.LossTextboxYear.String = num2str(curr);
            this.Handles.LossTextboxYear.UserData = curr;
            
            switch (curr)
                case lim_beg
                    this.Handles.LossButtonYearMinus.Enable = 'off';
                    this.Handles.LossButtonYearPlus.Enable = 'on';
                case lim_end
                    this.Handles.LossButtonYearMinus.Enable = 'on';
                    this.Handles.LossButtonYearPlus.Enable = 'off';
                otherwise
                    this.Handles.LossButtonYearMinus.Enable = 'on';
                    this.Handles.LossButtonYearPlus.Enable = 'on';
            end
        end
        
        function LossCheckboxTransition_CheckedChanged(this,obj,evd) %#ok<INUSD>
            yea = this.Year - 10;
            this.Handles.LossTextboxYear.String = num2str(yea);
            this.Handles.LossTextboxYear.UserData = yea;
            
            if (obj.Value == 1)
                if (this.Handles.LossTextboxThreshold.UserData == 10000)
                    this.Handles.LossButtonThresholdPlus.Enable = 'on';
                end
                
                this.Handles.LossTextYear.Enable = 'on';
                this.Handles.LossTextboxYear.Enable = 'inactive';
                this.Handles.LossButtonYearPlus.Enable = 'on';
                
                this.Transition = true;
            else
                if (this.Handles.LossTextboxThreshold.UserData > 10000)
                    this.Handles.LossTextboxThreshold.String = '10000';
                    this.Handles.LossTextboxThreshold.UserData = 10000;
                    
                    this.Handles.LossButtonThresholdPlus.Enable = 'off';
                end
                
                this.Handles.LossTextYear.Enable = 'off';
                this.Handles.LossButtonYearMinus.Enable = 'off';
                this.Handles.LossTextboxYear.Enable = 'off';
                this.Handles.LossButtonYearPlus.Enable = 'off';
                
                this.Transition = false;
            end
        end
        
        function TableColumnHeader_Clicked(this,obj,evd) %#ok<INUSL>
            import('javax.swing.SwingUtilities');
            
            sort = obj.isSortable();
            
            if (~sort && ~SwingUtilities.isLeftMouseButton(evd))
                return;
            elseif (sort && ~SwingUtilities.isRightMouseButton(evd))
                return;
            end
            
            col = obj.columnAtPoint(evd.getPoint());
            col_idx = obj.convertColumnIndexToModel(col);
            
            sel_mod = obj.getTableSelectionModel();
            
            if (evd.isControlDown())
                for i = 0:obj.getRowCount()-1
                    sel_mod.addSelection(i,col_idx);
                end
            else
                sel_mod.setSelectionInterval(0,(obj.getRowCount() - 1),col_idx);
            end
        end
        
        function TableRowHeader_Clicked(this,obj,evd) %#ok<INUSL>
            import('javax.swing.SwingUtilities');
            
            if (~SwingUtilities.isLeftMouseButton(evd))
                return;
            end
            
            row = obj.rowAtPoint(evd.getPoint());
            row_idx = obj.convertRowIndexToModel(row);
            
            if (~evd.isControlDown())
                obj.clearSelection();
            end
            
            sel_mod = obj.getTableSelectionModel();
            
            for i = 0:obj.getColumnCount()-1
                sel_mod.addSelection(row_idx,i);
            end
        end
    end
    
    %% Methods: Functions
    methods (Access = private)
        function [data,err] = DatasetAnalyze(this,data)
            err = [];
            
            thr = this.Handles.LossTextboxThreshold.UserData;
            date_from = datetime(this.Handles.LossTextboxYear.UserData,1,1);
            date_to = datetime((this.Year - 1),12,31);
            
            data = data((data.Date >= date_from) & (data.Date <= date_to) & (data.Loss >= thr),:);
            
            yea_seq = ((this.Year - 10):(this.Year - 1))';
            yea_uni = unique(year(sort(data.Date)));
            
            if (this.Transition)
                tra = false;
                
                for i = 1:6
                    if (isequal(yea_seq(i:end),yea_uni))
                        tra = true;
                        break;
                    end
                end
                
                if (~tra)
                    err = ['The dataset must contain a minimum of 5 years of loss events (from ' num2str(yea_seq(6)) ' to ' num2str(yea_seq(end)) ') and at least one event per year.'];
                    return;
                end
            elseif (~isequal(yea_seq,yea_uni))
                err = ['The dataset must contain 10 years of loss events (from ' num2str(yea_seq(1)) ' to ' num2str(yea_seq(end)) ') and at least one event per year.'];
                return;
            end
            
            yea_uni_len = numel(yea_uni);
            avg_all = sum(data.Loss) / yea_uni_len;
            avg_10 = sum(data.Loss(data.Loss > 10e6)) / yea_uni_len;
            avg_100 = sum(data.Loss(data.Loss > 100e6)) / yea_uni_len;
            lc = (7 * avg_all) + (7 * avg_10) + (5 * avg_100);
            
            vars = cell(4,2);
            vars(:,1) = {'AVG ALL' 'AVG 10' 'AVG 100' 'LC'};
            vars(:,2) = {avg_all avg_10 avg_100 lc};
            
            data = sortrows(data,'ID');
            data.ID = int32(data.ID);
            data.Date = datenum(data.Date);
            
            data_max_id = data.ID(end);
            data_max_loss = max(data.Loss);
            data_max_rec = max(data.Recovery);
            data_ds = table2cell(data);
            
            data = struct();
            data.Dataset = data_ds;
            data.MaximumID = data_max_id;
            data.MaximumLoss = data_max_loss;
            data.MaximumRecovery = data_max_rec;
            data.Variables = vars;
        end
        
        function [data,err] = DatasetLoad(this,file) %#ok<INUSL>
            err = [];
            
            if (exist(file,'file') == 0)
                err = 'The dataset file does not exist.';
                return;
            end
            
            [file_sta,file_shts,file_fmt] = xlsfinfo(file);
            
            if (isempty(file_sta) || ~strcmp(file_fmt,'xlOpenXMLWorkbook'))
                err = 'The dataset file is not a valid Excel spreadsheet.';
                return;
            end
            
            if (numel(file_shts) ~= 1)
                err = 'The dataset must contain only one sheet.';
                return;
            end
            
            try
                data = readtable(file);
            catch
                err = 'The dataset could not be read because of system errors or invalid values.';
                return;
            end
            
            if (isempty(data))
                err = 'The dataset is empty.';
                return;
            end
            
            if (~isequal(strtrim(data.Properties.VariableNames),{'ID' 'Date' 'BusinessLine' 'RiskCategory' 'GrossLossAmount' 'RecoveryAmount'}))
                err = 'The dataset is invalid because of wrong columns count, names and/or order.';
                return;
            end
            
            data.Properties.VariableNames = {'ID' 'Date' 'BL' 'RC' 'Loss' 'Recovery'};
        end
        
        function err = DatasetValidate(this,data) %#ok<INUSL>
            err = [];
            
            if (~isa(data.ID,'double'))
                err = 'The ID column type is invalid.';
                return;
            end
            
            mis = ismissing(data.ID);
            
            if (any(mis))
                rows = (1:height(data))';
                ref = rows(mis) + 1;
                
                if (numel(ref) == 1)
                    err = ['The ID column contains a missing value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The ID column contains missing values at rows: ",strjoin(string(ref),", "),"."));
                end
                
                return;
            end
            
            inv = ~isreal(data.ID) | ~isfinite(data.ID) | ((data.ID - floor(data.ID)) > 0) | (data.ID <= 0);
            
            if (any(inv))
                rows = (1:height(data))';
                ref = rows(inv) + 1;
                
                if (numel(ref) == 1)
                    err = ['The ID column contains an invalid value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The ID column contains invalid values at rows: ",strjoin(string(ref),', '),"."));
                end
                
                return;
            end
            
            [~,idx] = unique(data.ID);
            dup = setdiff(1:numel(data.ID),idx) + 1;
            
            if (~isempty(dup))
                if (numel(dup) == 1)
                    err = ['The ID column contains a duplicate value at row ' num2str(dup) '.'];
                else
                    err = char(strcat("The ID column contains duplicate values at rows: ",strjoin(string(dup),', '),"."));
                end
                
                return;
            end
            
            mis = ismissing(data.Date);
            
            if (any(mis))
                rows = (1:height(data))';
                ref = rows(mis) + 1;
                
                if (numel(ref) == 1)
                    err = ['The Date column contains a missing value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The Date column contains missing values at rows: ",strjoin(string(ref),", "),"."));
                end
                
                return;
            end
            
            if (~isa(data.Date,'datetime'))
                import('baseltools.*');
                df = Environment.DateFormat;
                
                ds_len = height(data);
                inv = false(ds_len,1);
                
                for i = 1:height(data)
                    try
                        df.parse(data.Date{i});
                    catch
                        inv(i) = true;
                    end
                end
                
                if (any(inv))
                    rows = (1:height(data))';
                    ref = rows(inv) + 1;
                    
                    if (numel(ref) == 1)
                        err = ['The Date column contains an invalid value at row ' num2str(ref) '.'];
                    else
                        err = char(strcat("The Date column contains invalid values at rows: ",strjoin(string(ref),', '),"."));
                    end
                else
                    err = 'The Date column type is invalid.';
                end
                
                return;
            end
            
            if (~iscell(data.BL))
                err = 'The BusinessLine column type is invalid.';
                return;
            end
            
            mis = ismissing(data.BL);
            
            if (any(mis))
                rows = (1:height(data))';
                ref = rows(mis) + 1;
                
                if (numel(ref) == 1)
                    err = ['The BusinessLine column contains a missing value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The BusinessLine column contains missing values at rows: ",strjoin(string(ref),", "),"."));
                end
                
                return;
            end
            
            inv = ~ismember(data.BL,{'AG' 'AM' 'CB' 'CF' 'PS' 'RBA' 'RBR' 'TS'});
            
            if (any(inv))
                rows = (1:height(data))';
                ref = rows(inv) + 1;
                
                if (numel(ref) == 1)
                    err = ['The BusinessLine column contains an invalid value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The BusinessLine column contains invalid values at rows: ",strjoin(string(ref),', '),"."));
                end
                
                return;
            end
            
            if (~iscell(data.RC))
                err = 'The RiskCategory column type is invalid.';
                return;
            end
            
            mis = ismissing(data.RC);
            
            if (any(mis))
                rows = (1:height(data))';
                ref = rows(mis) + 1;
                
                if (numel(ref) == 1)
                    err = ['The RiskCategory column contains a missing value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The RiskCategory column contains missing values at rows: ",strjoin(string(ref),", "),"."));
                end
                
                return;
            end
            
            inv = ~ismember(data.RC,{'BDSF' 'CPBP' 'DPA' 'EDPM' 'EPWS' 'EF' 'IF'});
            
            if (any(inv))
                rows = (1:height(data))';
                ref = rows(inv) + 1;
                
                if (numel(ref) == 1)
                    err = ['The RiskCategory column contains an invalid value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The RiskCategory column contains invalid values at rows: ",strjoin(string(ref),', '),"."));
                end
                
                return;
            end
            
            if (~isa(data.Loss,'double'))
                err = 'The GrossLossAmount column type is invalid.';
                return;
            end
            
            mis = ismissing(data.Loss);
            
            if (any(mis))
                rows = (1:height(data))';
                ref = rows(mis) + 1;
                
                if (numel(ref) == 1)
                    err = ['The GrossLossAmount column contains a missing value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The GrossLossAmount column contains missing values at rows: ",strjoin(string(ref),", "),"."));
                end
                
                return;
            end
            
            inv = ~isreal(data.Loss) | ~isfinite(data.Loss) | (data.Loss <= 0);
            
            if (any(inv))
                rows = (1:height(data))';
                ref = rows(inv) + 1;
                
                if (numel(ref) == 1)
                    err = ['The GrossLossAmount column contains an invalid value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The GrossLossAmount column contains invalid values at rows: ",strjoin(string(ref),', '),"."));
                end
                
                return;
            end
            
            if (~isa(data.Recovery,'double'))
                err = 'The RecoveryAmount column type is invalid.';
                return;
            end
            
            mis = ismissing(data.Recovery);
            
            if (any(mis))
                rows = (1:height(data))';
                ref = rows(mis) + 1;
                
                if (numel(ref) == 1)
                    err = ['The RecoveryAmount column contains a missing value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The RecoveryAmount column contains missing values at rows: ",strjoin(string(ref),", "),"."));
                end
                
                return;
            end
            
            inv = ~isreal(data.Recovery) | ~isfinite(data.Recovery) | (data.Recovery <= 0) | (data.Recovery > data.Loss);
            
            if (any(inv))
                rows = (1:height(data))';
                ref = rows(inv) + 1;
                
                if (numel(ref) == 1)
                    err = ['The RecoveryAmount column contains an invalid value at row ' num2str(ref) '.'];
                else
                    err = char(strcat("The RecoveryAmount column contains invalid values at rows: ",strjoin(string(ref),', '),"."));
                end
                
                return;
            end
        end
        
        function err = ExportData(this,file)
            err = [];
            
            try
                exc = actxserver('Excel.Application');
                exc.DisplayAlerts = false;
                exc.Interactive = false;
                exc.ScreenUpdating = false;
                exc.UserControl = false;
                exc.Visible = false;
                
                exc_wb = exc.Workbooks.Add();
            catch
                err = 'The exportation process failed: the application was unable to create an Excel COM Object.';
                return;
            end
            
            try
                jpan_cap_rslt = javaObjectEDT(findjobj(this.Handles.CapitalTableResult));
                jtab_cap_rslt = javaObjectEDT(jpan_cap_rslt.getViewport().getView());
                jtab_cap_rslt_cell = cell(jtab_cap_rslt.getModel().getData());
                
                ilm = jtab_cap_rslt_cell{3,2};
                k_sma = jtab_cap_rslt_cell{4,2};
                k_b2 = jtab_cap_rslt_cell{5,2};
                
                exc_sh1 = exc_wb.Worksheets.Item(1);
                
                if (this.Handles.CapitalCheckboxCompact.Value == 0)
                    this.ExportDataResultFull(exc,exc_sh1,ilm,k_sma);
                    
                    exc_sh = exc_wb.Worksheets.Item(3);
                    
                    if (this.Handles.CapitalCheckboxComparison.Value == 0)
                        exc_sh.Delete();
                    else
                        this.ExportDataComparison(exc,exc_sh,k_b2);
                    end
                    
                    exc_sh = exc_wb.Worksheets.Item(2);
                    
                    if (this.Handles.CapitalCheckboxLoss.Value == 0)
                        exc_sh.Delete();
                    else
                        this.ExportDataLoss(exc,exc_sh);
                    end
                else
                    this.ExportDataResultCompact(exc,exc_sh1,ilm,k_sma,k_b2);
                    exc_wb.Worksheets.Item(3).Delete();
                    exc_wb.Worksheets.Item(2).Delete();
                end
                
                exc_sh1.Activate();
                exc_wb.SaveAs(file);
            catch e
                err = ['The exportation process failed. The exception produced is: "' regexprep(strtrim(e.message),'[\n\r]+',' ') '".'];
            end
            
            exc_wb.Close();
            exc.Quit();
            
            delete(exc);
        end
        
        function ExportDataComparison(this,exc,exc_sh,k)
            jpan_cap_cmpr = javaObjectEDT(findjobj(this.Handles.CapitalTableComparison));
            jtab_cap_cmpr = javaObjectEDT(jpan_cap_cmpr.getViewport().getView());
            jtab_cap_cmpr_cell = cell(jtab_cap_cmpr.getModel().getData());
            
            if (this.Handles.CapitalRadiobuttonBIA.Value == 1)
                app = 'BIA';
            elseif (this.Handles.CapitalRadiobuttonTSA.Value == 1)
                app = 'TSA';
            else
                app = 'ASA';
            end
            
            cmp = [
                {[] ['Approach: ' app] [] []};
                ['Year'; strrep(this.Handles.CapitalTableComparison.ColumnName(2:end),'Value ','')]';
                jtab_cap_cmpr_cell
                ];
            
            exc_sh.Name = 'BII Comparison';
            exc_sh.Columns.Item('A:I').ColumnWidth = 20;
            exc.Union(exc_sh.Columns.Item('A:B'), ...
                exc_sh.Columns.Item('F:G'), ...
                exc_sh.Columns.Item('I')).ColumnWidth = 12;
            
            ran_tab_tit = exc_sh.Range('B2:E2');
            ran_tab_hea = exc.Union(exc_sh.Range('B3:E3'), ...
                exc_sh.Range('B4:B11'));
            ran_tab_data = exc_sh.Range('C4:E11');
            ran_tab = exc.Union(ran_tab_tit, ...
                ran_tab_hea, ...
                ran_tab_data);
            
            ran_tab.HorizontalAlignment = -4108;
            ran_tab.VerticalAlignment = -4108;
            ran_tab.Value = cmp;
            
            ran_tab_tit.MergeCells = 1;
            ran_tab_data.NumberFormat = '#.##0,00';
            
            ran_res_tit = exc_sh.Range('G2');
            ran_res_data = exc_sh.Range('H2');
            ran_res = exc.Union(ran_res_tit, ...
                ran_res_data);
            
            ran_res.HorizontalAlignment = -4108;
            ran_res.VerticalAlignment = -4108;
            ran_res.Value = {'K' k [] []};
            
            ran_res_data.MergeCells = 1;
            ran_res_data.NumberFormat = '#.##0,00';
            
            if (this.Handles.CapitalCheckboxStyles.Value == 1)
                import('baseltools.*');
                
                clr_off = [1; 256; 65536];
                clr_tab = Environment.ColorOpCapK2;
                clr_tab = [clr_tab.getRed() clr_tab.getGreen() clr_tab.getBlue()] * clr_off;
                clr_res = Environment.ColorOpCapK1;
                clr_res = [clr_res.getRed() clr_res.getGreen() clr_res.getBlue()] * clr_off;
                
                ran_all = exc.Union(ran_tab, ...
                    ran_res);
                ran_all.Borders.ColorIndex = 1;
                ran_all.Borders.LineStyle = 1;
                ran_all.Borders.Weight = 2;
                ran_all.RowHeight = 22;
                
                ran_tit = exc.Union(ran_tab_tit, ...
                    ran_res_tit);
                ran_tit.Font.Bold = true;
                ran_tit.Font.Size = 16;
                
                ran_tab_hea.Font.Bold = true;
                ran_tab_hea.Font.Size = 12;
                
                exc.Union(ran_tab_tit, ...
                    ran_tab_hea).Interior.Color = clr_tab;
                
                ran_res_tit.Interior.Color = clr_res;
            end
        end
        
        function ExportDataLoss(this,exc,exc_sh)
            jpan_loss_ds = javaObjectEDT(findjobj(this.Handles.LossTableDataset));
            jtab_loss_ds = javaObjectEDT(jpan_loss_ds.getViewport().getView());
            
            jtab_loss_ds_cell = cell(jtab_loss_ds.getModel().getActualModel().getData());
            jtab_loss_ds_cell(:,2) = cellstr(datestr([jtab_loss_ds_cell{:,2}]','dd/mm/yyyy'));
            
            loss = [
                this.Handles.LossTableDataset.ColumnName';
                jtab_loss_ds_cell
                ];
            loss_len = num2str(size(loss,1));
            
            exc_sh.Name = 'Loss Dataset';
            exc_sh.Columns.Item('A:b').ColumnWidth = 14;
            exc_sh.Columns.Item('C:D').ColumnWidth = 22;
            exc_sh.Columns.Item('E:F').ColumnWidth = 29;
            
            ran_tab = exc_sh.Range(['A1:F' loss_len]);
            ran_tab.HorizontalAlignment = -4108;
            ran_tab.VerticalAlignment = -4108;
            ran_tab.Value = loss;
            
            exc_sh.Range(['A2:A' loss_len]).NumberFormat = '0';
            exc_sh.Range(['C2:D' loss_len]).NumberFormat = '@';
            exc_sh.Range(['E2:F' loss_len]).NumberFormat = '#.##0,00';
            
            if (this.Handles.CapitalCheckboxStyles.Value == 1)
                import('baseltools.*');
                
                clr_off = [1; 256; 65536];
                clr_hea = Environment.ColorOpLossLC;
                clr_hea = [clr_hea.getRed() clr_hea.getGreen() clr_hea.getBlue()] * clr_off;
                clr_all = Environment.ColorOpLossAll;
                clr_all = [clr_all.getRed() clr_all.getGreen() clr_all.getBlue()] * clr_off;
                
                gl = [jtab_loss_ds_cell{:,5}]';
                gl_ref = arrayfun(@num2str,(2:(numel(gl)+1))','UniformOutput',false);
                gl_10 = gl_ref((gl > 10e6) & (gl <= 100e6));
                gl_10_len = numel(gl_10);
                gl_100 = gl_ref(gl > 100e6);
                gl_100_len = numel(gl_100);
                
                exc_sh.Activate();
                exc_sh.Application.ActiveWindow.SplitRow = 1;
                exc_sh.Application.ActiveWindow.FreezePanes = true;
                
                ran_tab.Borders.ColorIndex = 1;
                ran_tab.Borders.LineStyle = 1;
                ran_tab.Borders.Weight = 2;
                ran_tab.Interior.Color = clr_all;
                
                ran_tab_hea = exc_sh.Range('A1:F1');
                ran_tab_hea.AutoFilter();
                ran_tab_hea.Borders.ColorIndex = 1;
                ran_tab_hea.Borders.LineStyle = 1;
                ran_tab_hea.Borders.Weight = 2;
                ran_tab_hea.Font.Bold = true;
                ran_tab_hea.Font.Size = 16;
                ran_tab_hea.Interior.Color = clr_hea;
                ran_tab_hea.RowHeight = 22;
                
                if (gl_10_len > 0)
                    clr_10 = Environment.ColorOpLoss10;
                    clr_10 = [clr_10.getRed() clr_10.getGreen() clr_10.getBlue()] * clr_off;
                    
                    gl_ref_1 = gl_10{1};
                    ran_10 = exc_sh.Range(['A' gl_ref_1 ':F' gl_ref_1]);
                    
                    for i = 2:gl_10_len
                        gl_ref_i = gl_10{i};
                        ran_10 = exc.Union(ran_10,exc_sh.Range(['A' gl_ref_i ':F' gl_ref_i]));
                    end
                    
                    ran_10.Interior.Color = clr_10;
                end
                
                if (gl_100_len > 0)
                    clr_100 = Environment.ColorOpLoss100;
                    clr_100 = [clr_100.getRed() clr_100.getGreen() clr_100.getBlue()] * clr_off;
                    
                    gl_ref_1 = gl_100{1};
                    ran_100 = exc_sh.Range(['A' gl_ref_1 ':F' gl_ref_1]);
                    
                    for i = 2:gl_100_len
                        gl_ref_i = gl_100{i};
                        ran_100 = exc.Union(ran_100,exc_sh.Range(['A' gl_ref_i ':F' gl_ref_i]));
                    end
                    
                    ran_100.Interior.Color = clr_100;
                end
            end
        end
        
        function ExportDataResultCompact(this,exc,exc_sh,ilm,k_sma,k_b2)
            has_cmpr = (this.Handles.CapitalCheckboxComparison.Value == 1);
            has_loss = ~ischar(ilm);
            
            jpan_bus_rslt = javaObjectEDT(findjobj(this.Handles.BusinessTableResult));
            jtab_bus_rslt = javaObjectEDT(jpan_bus_rslt.getViewport().getView());
            jtab_bus_rslt_cell = cell(jtab_bus_rslt.getModel().getData());
            
            vars_sep = {[] []};
            vars = [
                jtab_bus_rslt_cell(1:3,:);
                vars_sep;
                jtab_bus_rslt_cell(4:5,:);
                ];
            
            jpan_bus_comp = javaObjectEDT(findjobj(this.Handles.BusinessTableComponent));
            jtab_bus_comp = javaObjectEDT(jpan_bus_comp.getViewport().getView());
            jtab_bus_comp_cell = cell(jtab_bus_comp.getModel().getData());
            
            for i = 1:5
                bic = jtab_bus_comp_cell{i,3};
                
                if (~ischar(bic))
                    vars(7,:) = {['BIC (' num2str(i) ')'] bic};
                    break;
                end
            end
            
            if (has_loss)
                jpan_loss_rslt = javaObjectEDT(findjobj(this.Handles.LossTableResult));
                jtab_loss_rslt = javaObjectEDT(jpan_loss_rslt.getViewport().getView());
                
                vars(8,:) = vars_sep;
                vars(9:12,:) = cell(jtab_loss_rslt.getModel().getData());
                vars(13,:) = vars_sep;
                vars(14,:) = {'ILM' ilm};
                
                if (has_cmpr)
                    vars(15,:) = {'K SMA' k_sma};
                    vars(16,:) = vars_sep;
                    vars(17,:) = {'K BII' k_b2};
                else
                    vars(15,:) = {'K' k_sma};
                end
            else
                vars(8,:) = vars_sep;
                
                if (has_cmpr)
                    vars(9,:) = {'K SMA' k_sma};
                    vars(10,:) = vars_sep;
                    vars(11,:) = {'K BII' k_b2};
                else
                    vars(9,:) = {'K' k_sma};
                end
            end
            
            exc_sh.Name = ['Result ' datestr(now(),'dd-mm-yyyy')];
            exc_sh.Columns.Item('A:D').ColumnWidth = 12;
            exc_sh.Columns.Item('C').ColumnWidth = 20;
            
            if (has_loss)
                ran = exc_sh.Range('B2:C16');
                ran_data = exc.Union(exc_sh.Range('C2:C4'), ...
                    exc_sh.Range('C6:C8'), ...
                    exc_sh.Range('C10:C13'), ...
                    exc_sh.Range('C16'));
                
                if (has_cmpr)
                    ran = exc.Union(ran, ...
                        exc_sh.Range('B17:C18'));
                    ran_data = exc.Union(ran_data, ...
                        exc_sh.Range('C18'));
                end
                
                exc_sh.Range('C15').NumberFormat = '#.##0,0000';
            else
                ran = exc_sh.Range('B2:C10');
                ran_data = exc.Union(exc_sh.Range('C2:C4'), ...
                    exc_sh.Range('C6:C8'), ...
                    exc_sh.Range('C10'));
                
                if (has_cmpr)
                    ran = exc.Union(ran, ...
                        exc_sh.Range('B11:C12'));
                    ran_data = exc.Union(ran_data, ...
                        exc_sh.Range('C12'));
                end
            end
            
            ran.HorizontalAlignment = -4108;
            ran.VerticalAlignment = -4108;
            ran.Value = vars;
            
            ran_data.NumberFormat = '#.##0,00';
            
            if (this.Handles.CapitalCheckboxStyles.Value == 1)
                import('baseltools.*');
                
                clr_off = [1; 256; 65536];
                clr_ildc = Environment.ColorOpBusILDC;
                clr_fc = Environment.ColorOpBusFC;
                clr_sc = Environment.ColorOpBusSC;
                clr_ubi = Environment.ColorOpBusUBI;
                clr_bi = Environment.ColorOpBusBI;
                clr_bic = Environment.ColorOpBusBIC;
                clr_ksma = Environment.ColorOpCapK1;
                
                ran_ildc = exc_sh.Range('B2');
                ran_fc = exc_sh.Range('B3');
                ran_sc = exc_sh.Range('B4');
                ran_ubi = exc_sh.Range('B6');
                ran_bi = exc_sh.Range('B7');
                ran_bic = exc_sh.Range('B8');
                
                if (has_loss)
                    ran_vars = exc.Union(exc_sh.Range('B2:C4'), ...
                        exc_sh.Range('B6:C8'), ...
                        exc_sh.Range('B10:C13'), ...
                        exc_sh.Range('B15:C16'));
                    
                    ran_lall = exc_sh.Range('B10');
                    ran_l10 = exc_sh.Range('B11');
                    ran_l100 = exc_sh.Range('B12');
                    ran_lc = exc_sh.Range('B13');
                    ran_ilm = exc_sh.Range('B15');
                    ran_ksma = exc_sh.Range('B16');
                    
                    ran_tit_oth = exc.Union(ran_lall, ...
                        ran_l10, ...
                        ran_l100, ...
                        ran_lc, ...
                        ran_ilm, ...
                        ran_ksma);
                    
                    if (has_cmpr)
                        ran_vars = exc.Union(ran_vars, ...
                            exc_sh.Range('B18:C18'));
                        
                        ran_kb2 = exc_sh.Range('B18');
                        
                        ran_tit_oth = exc.Union(ran_tit_oth, ...
                            ran_kb2);
                    end
                else
                    ran_vars = exc.Union(exc_sh.Range('B2:C4'), ...
                        exc_sh.Range('B6:C8'), ...
                        exc_sh.Range('B10:C10'));
                    
                    ran_ksma = exc_sh.Range('B10');
                    
                    ran_tit_oth = ran_ksma;
                    
                    if (has_cmpr)
                        ran_vars = exc.Union(ran_vars, ...
                            exc_sh.Range('B12:C12'));
                        
                        ran_kb2 = exc_sh.Range('B12');
                        
                        ran_tit_oth = exc.Union(ran_tit_oth, ...
                            ran_kb2);
                    end
                end
                
                ran_vars.Borders.ColorIndex = 1;
                ran_vars.Borders.LineStyle = 1;
                ran_vars.Borders.Weight = 2;
                ran_vars.RowHeight = 22;
                
                ran_tit = exc.Union(ran_ildc, ...
                    ran_fc, ...
                    ran_sc, ...
                    ran_ubi, ...
                    ran_bi, ...
                    ran_bic, ...
                    ran_tit_oth);
                ran_tit.Font.Bold = true;
                ran_tit.Font.Size = 16;
                
                ran_ildc.Interior.Color = [clr_ildc.getRed() clr_ildc.getGreen() clr_ildc.getBlue()] * clr_off;
                ran_fc.Interior.Color = [clr_fc.getRed() clr_fc.getGreen() clr_fc.getBlue()] * clr_off;
                ran_sc.Interior.Color = [clr_sc.getRed() clr_sc.getGreen() clr_sc.getBlue()] * clr_off;
                ran_ubi.Interior.Color = [clr_ubi.getRed() clr_ubi.getGreen() clr_ubi.getBlue()] * clr_off;
                ran_bi.Interior.Color = [clr_bi.getRed() clr_bi.getGreen() clr_bi.getBlue()] * clr_off;
                ran_bic.Interior.Color = [clr_bic.getRed() clr_bic.getGreen() clr_bic.getBlue()] * clr_off;
                
                if (has_loss)
                    clr_lall = Environment.ColorOpLossAll;
                    clr_l10 = Environment.ColorOpLoss10;
                    clr_l100 = Environment.ColorOpLoss100;
                    clr_lc = Environment.ColorOpLossLC;
                    clr_ilm = Environment.ColorOpCapAll;
                    
                    ran_lall.Interior.Color = [clr_lall.getRed() clr_lall.getGreen() clr_lall.getBlue()] * clr_off;
                    ran_l10.Interior.Color = [clr_l10.getRed() clr_l10.getGreen() clr_l10.getBlue()] * clr_off;
                    ran_l100.Interior.Color = [clr_l100.getRed() clr_l100.getGreen() clr_l100.getBlue()] * clr_off;
                    ran_lc.Interior.Color = [clr_lc.getRed() clr_lc.getGreen() clr_lc.getBlue()] * clr_off;
                    ran_ilm.Interior.Color = [clr_ilm.getRed() clr_ilm.getGreen() clr_ilm.getBlue()] * clr_off;
                end
                
                ran_ksma.Interior.Color = [clr_ksma.getRed() clr_ksma.getGreen() clr_ksma.getBlue()] * clr_off;
                
                if (has_cmpr)
                    clr_kb2 = Environment.ColorOpCapK2;
                    ran_kb2.Interior.Color = [clr_kb2.getRed() clr_kb2.getGreen() clr_kb2.getBlue()] * clr_off;
                end
            end
        end
        
        function ExportDataResultFull(this,exc,exc_sh,ilm,k)
            has_loss = ~ischar(ilm);
            
            jpan_bus_data = javaObjectEDT(findjobj(this.Handles.BusinessTableData));
            jtab_bus_data = javaObjectEDT(jpan_bus_data.getViewport().getView());
            jtab_bus_data_cell = cell(jtab_bus_data.getModel().getData());
            
            data_hea = ['Year'; strrep(this.Handles.BusinessTableData.ColumnName(2:end),'Value ','')]';
            data = [
                {[] 'Interest, Lease & Dividend Component' [] [] []};
                data_hea;
                jtab_bus_data_cell(2:7,:);
                cell(1,5);
                {[] 'Financial Component' [] [] []};
                data_hea;
                jtab_bus_data_cell(9:10,:);
                cell(1,5);
                {[] 'Services Component' [] [] []};
                data_hea;
                jtab_bus_data_cell(12:end,:)
                ];
            
            jpan_bus_rslt = javaObjectEDT(findjobj(this.Handles.BusinessTableResult));
            jtab_bus_rslt = javaObjectEDT(jpan_bus_rslt.getViewport().getView());
            jtab_bus_rslt_cell = cell(jtab_bus_rslt.getModel().getData());
            
            vars_sep = {[] []};
            vars = [
                jtab_bus_rslt_cell(1:3,:);
                vars_sep;
                jtab_bus_rslt_cell(4:5,:);
                ];
            
            jpan_bus_comp = javaObjectEDT(findjobj(this.Handles.BusinessTableComponent));
            jtab_bus_comp = javaObjectEDT(jpan_bus_comp.getViewport().getView());
            jtab_bus_comp_cell = cell(jtab_bus_comp.getModel().getData());
            
            for i = 1:5
                bic = jtab_bus_comp_cell{i,3};
                
                if (~ischar(bic))
                    vars(7,:) = {['BIC (' num2str(i) ')'] bic};
                    break;
                end
            end
            
            jpan_loss_rslt = javaObjectEDT(findjobj(this.Handles.LossTableResult));
            jtab_loss_rslt = javaObjectEDT(jpan_loss_rslt.getViewport().getView());
            
            if (has_loss)
                vars(8,:) = vars_sep;
                vars(9:12,:) = cell(jtab_loss_rslt.getModel().getData());
                vars(13,:) = vars_sep;
                vars(14,:) = {'ILM' ilm};
                vars(15,:) = {'K' k};
            else
                vars(8,:) = vars_sep;
                vars(9,:) = {'K' k};
            end
            
            exc_sh.Name = ['Result ' datestr(now(),'dd-mm-yyyy')];
            exc_sh.Columns.Item('A:J').ColumnWidth = 12;
            exc.Union(exc_sh.Columns.Item('C:F'), ...
                exc_sh.Columns.Item('I')).ColumnWidth = 20;
            
            ran_full = exc_sh.Range('B2:F21');
            
            ran_tab_ildc_tit = exc_sh.Range('B2:F2');
            ran_tab_ildc_hea = exc.Union(exc_sh.Range('B3:F3'), ...
                exc_sh.Range('B4:B9'));
            ran_tab_ildc_data = exc_sh.Range('C4:F9');
            ran_tab_ildc = exc.Union(ran_tab_ildc_tit, ...
                ran_tab_ildc_hea, ...
                ran_tab_ildc_data);
            
            ran_tab_fc_tit = exc_sh.Range('B11:F11');
            ran_tab_fc_hea = exc.Union(exc_sh.Range('B12:F12'), ...
                exc_sh.Range('B13:B14'));
            ran_tab_fc_data = exc_sh.Range('C13:F14');
            ran_tab_fc = exc.Union(ran_tab_fc_tit, ...
                ran_tab_fc_hea, ...
                ran_tab_fc_data);
            
            ran_tab_sc_tit = exc_sh.Range('B16:F16');
            ran_tab_sc_hea = exc.Union(exc_sh.Range('B17:F17'), ...
                exc_sh.Range('B18:B21'));
            ran_tab_sc_data = exc_sh.Range('C18:F21');
            ran_tab_sc = exc.Union(ran_tab_sc_tit, ...
                ran_tab_sc_hea, ...
                ran_tab_sc_data);
            
            ran_full.HorizontalAlignment = -4108;
            ran_full.VerticalAlignment = -4108;
            ran_full.Value = data;
            
            ran_tab_tits = exc.Union(ran_tab_ildc_tit, ...
                ran_tab_fc_tit, ...
                ran_tab_sc_tit);
            ran_tab_tits.MergeCells = 1;
            
            exc.Union(ran_tab_ildc_data, ...
                ran_tab_fc_data, ...
                ran_tab_sc_data).NumberFormat = '#.##0,00';
            
            if (has_loss)
                ran_vars = exc_sh.Range('H2:I16');
                ran_vars_tabs = exc.Union(exc_sh.Range('H2:I4'), ...
                    exc_sh.Range('H6:I8'), ...
                    exc_sh.Range('H10:I13'), ...
                    exc_sh.Range('H15:I16'));
                
                exc.Union(exc_sh.Range('I2:I4'), ...
                    exc_sh.Range('I6:I8'), ...
                    exc_sh.Range('I10:I13'), ...
                    exc_sh.Range('I16')).NumberFormat = '#.##0,00';
                exc_sh.Range('I15').NumberFormat = '#.##0,0000';
            else
                ran_vars = exc_sh.Range('H2:I10');
                ran_vars_tabs = exc.Union(exc_sh.Range('H2:I4'), ...
                    exc_sh.Range('H6:I8'), ...
                    exc_sh.Range('H10:I10'));
                
                exc.Union(exc_sh.Range('I2:I4'), ...
                    exc_sh.Range('I6:I8'), ...
                    exc_sh.Range('I11')).NumberFormat = '#.##0,00';
            end
            
            ran_vars.HorizontalAlignment = -4108;
            ran_vars.VerticalAlignment = -4108;
            ran_vars.Value = vars;
            
            if (this.Handles.CapitalCheckboxStyles.Value == 1)
                import('baseltools.*');
                
                clr_off = [1; 256; 65536];
                clr_ildc = Environment.ColorOpBusILDC;
                clr_fc = Environment.ColorOpBusFC;
                clr_sc = Environment.ColorOpBusSC;
                clr_ubi = Environment.ColorOpBusUBI;
                clr_bi = Environment.ColorOpBusBI;
                clr_bic = Environment.ColorOpBusBIC;
                clr_k = Environment.ColorOpCapK1;
                
                ran_vars_ildc = exc_sh.Range('H2');
                ran_vars_fc = exc_sh.Range('H3');
                ran_vars_sc = exc_sh.Range('H4');
                ran_vars_ubi = exc_sh.Range('H6');
                ran_vars_bi = exc_sh.Range('H7');
                ran_vars_bic = exc_sh.Range('H8');
                
                if (has_loss)
                    ran_vars_lall = exc_sh.Range('H10');
                    ran_vars_l10 = exc_sh.Range('H11');
                    ran_vars_l100 = exc_sh.Range('H12');
                    ran_vars_lc = exc_sh.Range('H13');
                    ran_vars_ilm = exc_sh.Range('H15');
                    ran_vars_k = exc_sh.Range('H16');
                    
                    ran_tits_oth = exc.Union(ran_vars_lall, ...
                        ran_vars_l10, ...
                        ran_vars_l100, ...
                        ran_vars_lc, ...
                        ran_vars_ilm, ...
                        ran_vars_k);
                else
                    ran_vars_k = exc_sh.Range('H10');
                    ran_tits_oth = ran_vars_k;
                end
                
                ran_full.RowHeight = 22;
                
                ran_tabs = exc.Union(ran_tab_ildc, ...
                    ran_tab_fc, ...
                    ran_tab_sc, ...
                    ran_vars_tabs);
                ran_tabs.Borders.ColorIndex = 1;
                ran_tabs.Borders.LineStyle = 1;
                ran_tabs.Borders.Weight = 2;
                
                ran_tits = exc.Union(ran_tab_tits, ...
                    ran_vars_ildc, ...
                    ran_vars_fc, ...
                    ran_vars_sc, ...
                    ran_vars_ubi, ...
                    ran_vars_bi, ...
                    ran_vars_bic, ...
                    ran_tits_oth);
                ran_tits.Font.Bold = true;
                ran_tits.Font.Size = 16;
                
                ran_heas = exc.Union(ran_tab_ildc_hea, ...
                    ran_tab_fc_hea, ...
                    ran_tab_sc_hea);
                ran_heas.Font.Bold = true;
                ran_heas.Font.Size = 12;
                
                exc.Union(ran_tab_ildc_tit, ...
                    ran_tab_ildc_hea, ...
                    ran_vars_ildc).Interior.Color = [clr_ildc.getRed() clr_ildc.getGreen() clr_ildc.getBlue()] * clr_off;
                
                exc.Union(ran_tab_fc_tit, ...
                    ran_tab_fc_hea, ...
                    ran_vars_fc).Interior.Color = [clr_fc.getRed() clr_fc.getGreen() clr_fc.getBlue()] * clr_off;
                
                exc.Union(ran_tab_sc_tit, ...
                    ran_tab_sc_hea, ...
                    ran_vars_sc).Interior.Color = [clr_sc.getRed() clr_sc.getGreen() clr_sc.getBlue()] * clr_off;
                
                ran_vars_ubi.Interior.Color = [clr_ubi.getRed() clr_ubi.getGreen() clr_ubi.getBlue()] * clr_off;
                ran_vars_bi.Interior.Color = [clr_bi.getRed() clr_bi.getGreen() clr_bi.getBlue()] * clr_off;
                ran_vars_bic.Interior.Color = [clr_bic.getRed() clr_bic.getGreen() clr_bic.getBlue()] * clr_off;
                
                if (has_loss)
                    clr_lall = Environment.ColorOpLossAll;
                    clr_l10 = Environment.ColorOpLoss10;
                    clr_l100 = Environment.ColorOpLoss100;
                    clr_lc = Environment.ColorOpLossLC;
                    clr_ilm = Environment.ColorOpCapAll;
                    
                    ran_vars_lall.Interior.Color = [clr_lall.getRed() clr_lall.getGreen() clr_lall.getBlue()] * clr_off;
                    ran_vars_l10.Interior.Color = [clr_l10.getRed() clr_l10.getGreen() clr_l10.getBlue()] * clr_off;
                    ran_vars_l100.Interior.Color = [clr_l100.getRed() clr_l100.getGreen() clr_l100.getBlue()] * clr_off;
                    ran_vars_lc.Interior.Color = [clr_lc.getRed() clr_lc.getGreen() clr_lc.getBlue()] * clr_off;
                    ran_vars_ilm.Interior.Color = [clr_ilm.getRed() clr_ilm.getGreen() clr_ilm.getBlue()] * clr_off;
                end
                
                ran_vars_k.Interior.Color = [clr_k.getRed() clr_k.getGreen() clr_k.getBlue()] * clr_off;
            end
        end
        
        function LossComponentDisable(this,new_data)
            this.Handles.LossButtonLoad.Enable = 'off';
            
            if (new_data)
                this.Handles.LossButtonClear.Enable = 'on';
                
                if (this.Handles.CapitalCheckboxCompact.Value == 0)
                    this.Handles.CapitalCheckboxLoss.Enable = 'on';
                end
            else
                this.Handles.LossButtonClear.Enable = 'off';
                
                this.Handles.CapitalCheckboxLoss.Value = 0;
                this.Handles.CapitalCheckboxLoss.Enable = 'off';
            end
            
            this.Handles.LossTextThreshold.Enable = 'off';
            this.Handles.LossButtonThresholdMinus.Enable = 'off';
            this.Handles.LossTextboxThreshold.Enable = 'off';
            this.Handles.LossButtonThresholdPlus.Enable = 'off';
            this.Handles.LossTextYear.Enable = 'off';
            this.Handles.LossButtonYearMinus.Enable = 'off';
            this.Handles.LossTextboxYear.Enable = 'off';
            this.Handles.LossButtonYearPlus.Enable = 'off';
            this.Handles.LossCheckboxTransition.Enable = 'off';
            
            if (~new_data)
                this.SetupTable(this.Handles.LossTableDataset, ...
                    'RowHeaderWidth',    56, ...
                    'Selection',         [false false false], ...
                    'Sorting',           2, ...
                    'VerticalScrollbar', true);
                this.SetupTable(this.Handles.LossTableResult, ...
                    'RowsHeight',        75, ...
                    'Selection',         [false false false]);
            end
        end
        
        function LossComponentEnable(this,cle_data)
            if (this.Transition)
                lim_thr = 20000;
                
                lim_yea_max = this.Year - 10;
                lim_yea_min = this.Year - 5;
                yea_box = 'inactive';
                
                switch (this.Handles.LossTextboxYear.UserData)
                    case lim_yea_max
                        yea_min = 'off';
                        yea_plu = 'on';
                    case lim_yea_min
                        yea_min = 'on';
                        yea_plu = 'off';
                    otherwise
                        yea_min = 'on';
                        yea_plu = 'on';
                end
            else
                lim_thr = 10000;
                
                yea_min = 'off';
                yea_box = 'off';
                yea_plu = 'off';
            end
            
            switch (this.Handles.LossTextboxThreshold.UserData)
                case 0
                    thr_min = 'off';
                    thr_plu = 'on';
                case lim_thr
                    thr_min = 'on';
                    thr_plu = 'off';
                otherwise
                    thr_min = 'on';
                    thr_plu = 'on';
            end
            
            this.Handles.LossButtonLoad.Enable = 'on';
            
            if (~cle_data)
                this.Handles.LossButtonClear.Enable = 'off';
            end
            
            this.Handles.LossTextThreshold.Enable = 'on';
            this.Handles.LossButtonThresholdMinus.Enable = thr_min;
            this.Handles.LossTextboxThreshold.Enable = 'inactive';
            this.Handles.LossButtonThresholdPlus.Enable = thr_plu;
            this.Handles.LossTextYear.Enable = 'on';
            this.Handles.LossButtonYearMinus.Enable = yea_min;
            this.Handles.LossTextboxYear.Enable = yea_box;
            this.Handles.LossButtonYearPlus.Enable = yea_plu;
            this.Handles.LossCheckboxTransition.Enable = 'on';
            
            if (cle_data)
                this.SetupTable(this.Handles.LossTableDataset, ...
                    'RowHeaderWidth',    56, ...
                    'Selection',         [false false false], ...
                    'Sorting',           2, ...
                    'VerticalScrollbar', true);
                this.SetupTable(this.Handles.LossTableResult, ...
                    'RowsHeight',        75, ...
                    'Selection',         [false false false]);
            end
            
            this.Handles.CapitalCheckboxLoss.Value = 0;
            this.Handles.CapitalCheckboxLoss.Enable = 'off';
        end
        
        function SetupBox(this,box,varargin) %#ok<INUSL>
            persistent ip;
            
            if (isempty(ip))
                ip = inputParser();
                ip.CaseSensitive = true;
                ip.addParameter('VerticalScrollbar',false,@(x)validateattributes(x,{'logical'},{'scalar'}));
            end
            
            if (isempty(box.UserData))
                return;
            end
            
            ip.parse(varargin{:});
            ip_res = ip.Results;
            
            html = box.UserData{1};
            box.UserData = [];
            
            import('javax.swing.*');
            import('javax.swing.text.html.*');
            import('baseltools.*');
            
            jpan = javaObjectEDT(findjobj(box));
            jbox = jpan.getViewport().getView();
            
            jpan.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
            
            if (ip_res.VerticalScrollbar)
                jpan.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
            else
                jpan.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
            end
            
            if (strcmp(box.Enable,'inactive'))
                jpan.setBorder(BorderFactory.createEmptyBorder());
                
                box_x = box.Position(1);
                box_y = box.Position(2);
                box_hei = box.Position(4);
                
                pan1 = uipanel(box.Parent);
                pan1.BorderType = 'none';
                pan1.BorderWidth = 0;
                pan1.Units = 'pixels';
                pan1.Position = [box_x box_y 2 box_hei];
                
                pan2 = uipanel(box.Parent);
                pan2.BorderType = 'none';
                pan2.BorderWidth = 0;
                pan2.Units = 'pixels';
                pan2.Position = [(box_x + box.Position(3) - 2) box_y 2 box_hei];
            end
            
            jbox.setDoubleBuffered(true);
            jbox.setEditable(false);
            jbox.setEditorKit(HTMLEditorKit());
            jbox.addHyperlinkListener(Environment.HyperlinkBrowser);
            jbox.setText(html);
        end
        
        function SetupTable(this,tab,varargin)
            persistent ip;
            
            if (isempty(ip))
                ip = inputParser();
                ip.CaseSensitive = true;
                
                ip.addParameter('Callback',[],@(x)validateattributes(x,{'function_handle'},{'scalar'}));
                ip.addParameter('Data',[],@(x)validateattributes(x,{'cell'},{'2d','nonempty'}));
                ip.addParameter('Editor',{'EditorDefault'},@(x)validateattributes(x,{'cell'},{'vector'}));
                ip.addParameter('Renderer',{'RendererDefault'},@(x)validateattributes(x,{'cell'},{'vector'}));
                ip.addParameter('RowHeaderWidth',0,@(x)validateattributes(x,{'numeric'},{'scalar','integer','real','finite','>=',1}));
                ip.addParameter('RowsHeight',0,@(x)validateattributes(x,{'numeric'},{'scalar','integer','real','finite','>=',1}));
                ip.addParameter('Selection',[true true true],@(x)validateattributes(x,{'logical'},{'vector','numel',3}));
                ip.addParameter('Sorting',0,@(x)validateattributes(x,{'numeric'},{'scalar','integer','real','finite','>=',0,'<=',2}));
                ip.addParameter('Table',{'TableDefault'},@(x)validateattributes(x,{'cell'},{'vector'}));
                ip.addParameter('VerticalScrollbar',false,@(x)validateattributes(x,{'logical'},{'scalar'}));
            end
            
            ip.parse(varargin{:});
            ip_res = ip.Results;
            
            tab.ColumnFormat = [];
            
            import('java.awt.*');
            import('javax.lang.*');
            import('javax.swing.*');
            import('com.jidesoft.grid.*');
            import('baseltools.*');
            
            jpan = javaObjectEDT(findjobj(tab,'Persist'));
            jvp = javaObjectEDT(jpan.getViewport());
            jtab = javaObjectEDT(jvp.getView());
            col_mod = javaObjectEDT(jtab.getColumnModel());
            hea_col = javaObjectEDT(jtab.getTableHeader());
            
            if (isempty(tab.RowName))
                hea_row = javaObjectEDT(JViewport());
            else
                hea_row = javaObjectEDT(jpan.getRowHeader());
            end
            
            if (numel(ip_res.Editor) == 1)
                tab_edi = javaObjectEDT(eval([ip_res.Editor{1} '()']));
            else
                tab_edi = javaObjectEDT(eval([ip_res.Editor{1} '(ip_res.Editor{2:end})']));
            end
            
            if (numel(ip_res.Table) == 1)
                tab_mod = eval([ip_res.Table{1} '(ip_res.Data,tab.ColumnName,tab.ColumnEditable)']);
            else
                tab_mod = eval([ip_res.Table{1} '(ip_res.Data,tab.ColumnName,tab.ColumnEditable,ip_res.Table{2:end})']);
            end
            
            if (numel(ip_res.Renderer) == 1)
                tab_ren = javaObjectEDT(eval([ip_res.Renderer{1} '()']));
            else
                tab_ren = javaObjectEDT(eval([ip_res.Renderer{1} '(ip_res.Renderer{2:end})']));
            end
            
            jpan.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
            
            if (ip_res.VerticalScrollbar)
                jpan.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
            else
                jpan.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
            end
            
            jtab.putClientProperty('terminateEditOnFocusLost',true);
            jtab.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
            jtab.setDoubleBuffered(true);
            jtab.setFillsViewportHeight(true);
            jtab.setKeepColumnAtPoint(true);
            jtab.setKeepRowAtPoint(true);
            jtab.setTableColumnWidthKeeper(DefaultTableColumnWidthKeeper());
            
            if (isempty(ip_res.Data))
                ip_res.Data = cell(0,numel(tab.ColumnName));
                
                clr = Environment.ColorDisabled;
                tab.Enable = 'off';
            else
                clr = Environment.ColorEnabled;
                tab.Enable = 'on';
            end
            
            jvp.setBackground(clr);
            hea_col.setBackground(clr);
            hea_row.setBackground(clr);
            
            jtab.setModel(tab_mod);
            
            if (~isempty(ip_res.Callback))
                cp = handle(tab_mod,'CallbackProperties');
                set(cp,'TableChangedCallback',@(obj,evd)ip_res.Callback(jtab,evd));
            end
            
            if (strcmp(tab.Enable,'off'))
                hea_col.setEnabled(false);
            else
                hea_col.setEnabled(true);
            end
            
            if (ip_res.Sorting == 0)
                jtab.setSortable(false);
            else
                jtab.setSortable(true);
                jtab.setAutoResort(true);
                jtab.setPreserveSelectionsAfterSorting(true);
                
                if (ip_res.Sorting == 1)
                    jtab.setMultiColumnSortable(false);
                else
                    jtab.setMultiColumnSortable(true);
                end
            end
            
            jtab.setSelectionMode(ListSelectionModel.MULTIPLE_INTERVAL_SELECTION);
            jtab.setCellSelectionEnabled(ip_res.Selection(1));
            jtab.setNonContiguousCellSelection(ip_res.Selection(1));
            jtab.setColumnSelectionAllowed(ip_res.Selection(2));
            jtab.setRowSelectionAllowed(ip_res.Selection(3));
            
            if (ip_res.Selection(2))
                if (ip_res.Sorting == 0)
                    hea_col.setToolTipText('<html><body><b>LClick:</b> Column Selection<br><b>CTRL+LClick:</b> Add Column to Current Selection</body></html>');
                else
                    hea_col.setToolTipText('<html><body><b>(CTRL+)LClick1:</b> Sort (Secondary) Ascending<br><b>(CTRL+)LClick2:</b> Sort (Secondary) Descending<br><b>(CTRL+)LClick3:</b> Unsort (Secondary)<br><br><b>RClick:</b> Column Selection<br><b>CTRL+RClick:</b> Add Column to Current Selection</body></html>');
                end
                
                cp = handle(hea_col,'CallbackProperties');
                set(cp,'MousePressedCallback',@(obj,evd)this.TableColumnHeader_Clicked(jtab,evd));
            end
            
            if (~isempty(tab.RowName))
                hea_row_view = javaObjectEDT(hea_row.getView());
                
                if (ip_res.RowHeaderWidth > 0)
                    hea_row_siz = Dimension(ip_res.RowHeaderWidth,hea_row_view.getHeight());
                    
                    hea_row.setPreferredSize(hea_row_siz);
                    hea_row.setSize(hea_row_siz);
                end
                
                if (ip_res.Selection(3))
                    hea_row_view.setToolTipText('<html><body><b>LClick:</b> Row Selection<br><b>CTRL+LClick:</b> Add Row to Current Selection</body></html>');
                    
                    cp = handle(hea_row_view,'CallbackProperties');
                    set(cp,'MousePressedCallback',@(obj,evd)this.TableRowHeader_Clicked(jtab,evd));
                end
            end
            
            if (ip_res.RowsHeight > 0)
                jtab.setRowHeight(ip_res.RowsHeight);
                
                rows = size(ip_res.Data,1);
                
                if (rows > 0)
                    hei_diff = tab.Position(4) - (rows * ip_res.RowsHeight) - 29;
                    
                    if (hei_diff > 0)
                        if (hei_diff < rows)
                            rows_off = 0;
                            
                            while (hei_diff > 0)
                                jtab.setRowHeight(rows_off,(ip_res.RowsHeight + 1));
                                rows_off = rows_off + 1;
                                
                                hei_diff = hei_diff - 1;
                            end
                        else
                            jtab.setRowHeight((rows - 1),(ip_res.RowsHeight + hei_diff));
                        end
                    end
                end
            end
            
            for i = 1:jtab.getColumnCount()
                col = javaObjectEDT(col_mod.getColumn(i - 1));
                col.setCellEditor(tab_edi);
                col.setCellRenderer(tab_ren);
                
                col_wid = tab.ColumnWidth{i};
                
                if (~ischar(col_wid))
                    col.setWidth(col_wid);
                end
                
                col.setResizable(false);
            end
            
            jtab.repaint();
        end
        
        function SetupTextbox(this,tb) %#ok<INUSL>
            import('java.awt.*');
            
            jtb = javaObjectEDT(findjobj(tb));
            jtb.setEditable(false);
            jtb.getCaret().setSelectionVisible(true);
        end
        
        function UpdateComparison(this,app)
            if (nargin < 2)
                if (this.Handles.CapitalRadiobuttonBIA.Value == 1)
                    app = 'BIA';
                elseif (this.Handles.CapitalRadiobuttonTSA.Value == 1)
                    app = 'TSA';
                else
                    app = 'ASA';
                end
            end
            
            jpan_cap_cmpr = javaObjectEDT(findjobj(this.Handles.CapitalTableComparison));
            jtab_cap_cmpr = javaObjectEDT(jpan_cap_cmpr.getViewport().getView());
            jtab_cap_cmpr_cell = cell(jtab_cap_cmpr.getModel().getData());
            
            val = cell2mat(jtab_cap_cmpr_cell(:,2:end));
            
            if (strcmp(app,'BIA'))
                val = sum(val);
                val(val <= 0) = [];
                
                if (isempty(val))
                    k = 0;
                else
                    val = val * 0.15;
                    k = round(mean(val),2);
                end
            else
                if (strcmp(app,'ASA'))
                    coe = [0.15; 0.12; 0.00525; 0.18; 0.18; 0.00420; 0.12; 0.18];
                else
                    coe = [0.15; 0.12; 0.15; 0.18; 0.18; 0.12; 0.12; 0.18];
                end
                
                val = val .* coe;
                val = sum(val);
                val(val < 0) = 0;
                
                k = round(mean(val),2);
            end
            
            jpan_cap_rslt = javaObjectEDT(findjobj(this.Handles.CapitalTableResult));
            jtab_cap_rslt = javaObjectEDT(jpan_cap_rslt.getViewport().getView());
            jtab_cap_rslt.setValueAt(k,4,1);
        end
        
        function UpdateData(this)
            jpan_bus_data = javaObjectEDT(findjobj(this.Handles.BusinessTableData));
            jtab_bus_data = javaObjectEDT(jpan_bus_data.getViewport().getView());
            jtab_bus_data_cell = cell(jtab_bus_data.getModel().getData());
            
            avg = cell2mat(jtab_bus_data_cell([2:7 9:10 12:15],5));
            
            i_diff = abs(avg(1) - avg(2));
            iea_cut = 0.035 * avg(3);
            l_diff = abs(avg(4) - avg(5));
            di = avg(6);
            ildc = min([i_diff iea_cut]) + l_diff + di;
            
            bb = avg(7);
            tb = avg(8);
            fc = bb + tb;
            
            f_diff = abs(avg(9) - avg(10));
            f_max = max(avg(9:10));
            oo_max = max(avg(11:12));
            ubi = ildc + f_max + oo_max + fc;
            ubi_half = 0.5 * ubi;
            ubi_comp = ubi_half + (0.1 * (f_max - ubi_half));
            sc =  max([f_diff min([f_max ubi_comp])]) + oo_max;
            
            bi = ildc + fc + sc;
            
            if (bi <= 1e9)
                buc = 1;
                bic = 0.11 * bi;
            elseif (bi <= 3e9)
                buc = 2;
                bic = 0.11e9 + (0.15 * (bi - 1e9));
            elseif (bi <= 10e9)
                buc = 3;
                bic = 0.41e9 + (0.19 * (bi - 3e9));
            elseif (bi <= 30e9)
                buc = 4;
                bic = 1.74e9 + (0.23 * (bi - 10e9));
            else
                buc = 5;
                bic = 6.34e9 + (0.29 * (bi - 30e9));
            end
            
            jpan_bus_rslt = javaObjectEDT(findjobj(this.Handles.BusinessTableResult));
            jtab_bus_rslt = javaObjectEDT(jpan_bus_rslt.getViewport().getView());
            
            jtab_bus_rslt.setValueAt(ildc,0,1);
            jtab_bus_rslt.setValueAt(fc,1,1);
            jtab_bus_rslt.setValueAt(sc,2,1);
            jtab_bus_rslt.setValueAt(ubi,3,1);
            jtab_bus_rslt.setValueAt(bi,4,1);
            
            jpan_bus_comp = javaObjectEDT(findjobj(this.Handles.BusinessTableComponent));
            jtab_bus_comp = javaObjectEDT(jpan_bus_comp.getViewport().getView());
            
            for i = 1:5
                if (i == buc)
                    jtab_bus_comp.setValueAt(bic,(i - 1),2);
                else
                    jtab_bus_comp.setValueAt('-',(i - 1),2);
                end
            end
            
            jtab_bus_comp.repaint();
            
            jpan_cap_rslt = javaObjectEDT(findjobj(this.Handles.CapitalTableResult));
            jtab_cap_rslt = javaObjectEDT(jpan_cap_rslt.getViewport().getView());
            
            if (buc == 1)
                jtab_cap_rslt.setValueAt('-',1,1);
                this.LossComponentDisable(false);
            elseif (ischar(jtab_cap_rslt.getValueAt(1,1)))
                this.LossComponentEnable(false);
            end
            
            this.UpdateCapital();
        end
        
        function UpdateCapital(this)
            jpan_bus_comp = javaObjectEDT(findjobj(this.Handles.BusinessTableComponent));
            jtab_bus_comp = javaObjectEDT(jpan_bus_comp.getViewport().getView());
            jtab_bus_comp_cell = cell(jtab_bus_comp.getModel().getData());
            
            for i = 1:5
                bic = jtab_bus_comp_cell{i,3};
                
                if (~ischar(bic))
                    break;
                end
            end
            
            jpan_cap_rslt = javaObjectEDT(findjobj(this.Handles.CapitalTableResult));
            jtab_cap_rslt = javaObjectEDT(jpan_cap_rslt.getViewport().getView());
            
            jtab_cap_rslt.setValueAt(bic,0,1);
            
            lc = jtab_cap_rslt.getValueAt(1,1);
            
            if (ischar(lc))
                k = bic;
                ilm = '-';
            else
                ilm = log(1.7183 + (lc / bic));
                k = 0.11e9 + ((bic - 0.11e9) * ilm);
            end
            
            jtab_cap_rslt.setValueAt(ilm,2,1);
            jtab_cap_rslt.setValueAt(k,3,1);
        end
    end
end
