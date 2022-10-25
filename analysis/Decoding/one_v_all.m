function accs = one_v_all(cfg0,data,labels)
    %Function that loops through classes and decodes in a one vs all manner.
    %Returns a matrix of [decoders x time points] accuracy values
    classes = unique(cfg0.labels);
    accs = [];
    for i = 1:length(classes)
    
        %Binarise classes
        pparam = {};
        pparam.target_class = i; %This is necessary to balance non-target classes when binarised
        cfg0.preprocess_param = {pparam}; 
        %Decode
        accuracy = mv_classify_across_time_BOB(cfg0,data,labels);
        accs = [accs accuracy];
        disp(accs)
        
    end

end