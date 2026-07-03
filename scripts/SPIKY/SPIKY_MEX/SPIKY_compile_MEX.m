% This is the first file that should be run once the zip-package has been extracted.
% Once the MEX-files have been compiled you can run the main program SPIKY.

% First run as it is, if you get an error message that involves the two
% variable types "char16_t"  and "unsigned short" please set problem to 1
% and try again. There are some known compiler incompatabilities but one
% of these two variants should usually work.

problem=0;

if problem==0
    
    mex -Dchar16_t=uint16_T SPIKY_udists_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_SPIKEsynchro_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_ISI_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_SPIKE_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_RI_SPIKE_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_realtimeSPIKE_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_forwardSPIKE_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_SPIKEpico_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_realtimeSPIKEpico_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_forwardSPIKEpico_MEX.c
    
    mex -Dchar16_t=uint16_T SPIKY_SPIKE_Neb_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_SPIKE_Eero_MEX.c
    mex -Dchar16_t=uint16_T SPIKY_SPIKE_Neb_Eero_MEX.c
    
    mex -Dchar16_t=uint16_T SPIKE_order_surro_MEX_alt.c
    mex -Dchar16_t=uint16_T SPIKE_order_sim_ann_MEX_alt.c
    % mex -Dchar16_t=uint16_T SPIKE_order_surro_MEX.c
    % mex -Dchar16_t=uint16_T SPIKE_order_sim_ann_MEX.c
    
else
    
    mex SPIKY_udists_MEX.c
    mex SPIKY_SPIKEsynchro_MEX.c
    mex SPIKY_ISI_MEX.c
    mex SPIKY_SPIKE_MEX.c
    mex SPIKY_RI_SPIKE_MEX.c
    mex SPIKY_realtimeSPIKE_MEX.c
    mex SPIKY_forwardSPIKE_MEX.c
    mex SPIKY_SPIKEpico_MEX.c
    mex SPIKY_realtimeSPIKEpico_MEX.c
    mex SPIKY_forwardSPIKEpico_MEX.c
    
    mex SPIKY_SPIKE_Neb_MEX.c
    mex SPIKY_SPIKE_Eero_MEX.c
    mex SPIKY_SPIKE_Neb_Eero_MEX.c
    
    mex SPIKE_order_surro_MEX_alt.c
    mex SPIKE_order_sim_ann_MEX_alt.c
    %mex SPIKE_order_surro_MEX.c
    %mex SPIKE_order_sim_ann_MEX.c
    
end



