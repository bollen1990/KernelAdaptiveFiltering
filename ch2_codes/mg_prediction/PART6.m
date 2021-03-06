%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Copyright Aaron Liu 
%CNEL
%July 1, 2008
%
%description:
%compare the performance of LMS, KLMS and RN for Mackey Glass time series
%one step prediction
%Monte Carlo simulation with different orders for polynormial kernel
%
%Usage:
%ch2, m-g prediction, tables 2-7
%
%Outside functions called:
%LMS1, KLMS1 and regularizationNetwork in toolBoxKAPA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all 
clear all 
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%       Data Formatting
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load MK30   %MK30 5000*1

MK30 = MK30(1000:5000);
varNoise = 0.0001;
inputDimension = 10; 

% Data size for training and testing
trainSize = 500;
testSize = 100;

% One step ahead prediction
predictionHorizon = 1;

%Kernel parameters
typeKernel = 'Poly';

paramKernel_v = [2,5,8];

%the KLMS step size is very sensitive to the order
stepSizeKlms1_v = [.1, .01, .0006];
    

for kkk = 1:length(paramKernel_v)
    paramKernel = paramKernel_v(kkk);

    %%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %       Parameters
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    stepSizeWeightLms1 = .04;
    stepSizeBiasLms1 = .04;

    stepSizeKlms1 = stepSizeKlms1_v(kkk);
    stepSizeWeightKlms1 = 0;
    stepSizeBiasKlms1 = 0;

    regularizationParameterRn = 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %       Monte Carlo
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    MC = 2;

    testMseLms1 = zeros(MC,1);
    testMseKlms1 = zeros(MC,1);
    testMseRn = zeros(MC,1);
    disp(['kernel param = ',num2str(paramKernel)]);
    disp([num2str(MC), ' Monte Carlo simulations']);
    
    for mc = 1:MC

        disp(mc)

        inputSignal = MK30 + sqrt(varNoise)*randn(size(MK30));
        inputSignal = inputSignal - mean(inputSignal);

        %Input training signal with data embedding
        trainInput = zeros(inputDimension,trainSize);
        for k = 1:trainSize
            trainInput(:,k) = inputSignal(k:k+inputDimension-1);
        end

        %Input test data with embedding
        testInput = zeros(inputDimension,testSize);
        for k = 1:testSize
            testInput(:,k) = inputSignal(k+trainSize:k+inputDimension-1+trainSize);
        end

        % Desired training signal
        trainTarget = zeros(trainSize,1);
        for ii=1:trainSize
            trainTarget(ii) = inputSignal(ii+inputDimension+predictionHorizon-1);
        end

        % Desired training signal
        testTarget = zeros(testSize,1);
        for ii=1:testSize
            testTarget(ii) = inputSignal(ii+inputDimension+trainSize+predictionHorizon-1);
        end
    % 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %             LMS 1
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [weightVectorLms1,biasTermLms1,learningCurveLms1]= ...
            LMS1(trainInput,trainTarget,stepSizeWeightLms1,stepSizeBiasLms1);

        err = testTarget -(testInput'*weightVectorLms1 + biasTermLms1);
        testMseLms1(mc) = mean(err.^2); 

        %=========end of Linear LMS 1================


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %               KLMS 1
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        [expansionCoefficientKlms1,weightVectorKlms1,biasTermKlms1,learningCurveKlms1] = ...
            KLMS1(trainInput,trainTarget,typeKernel,paramKernel,stepSizeKlms1,stepSizeWeightKlms1,stepSizeBiasKlms1);
        y_te = zeros(testSize,1);

        for jj = 1:testSize

            y_te(jj) = expansionCoefficientKlms1'*...
            ker_eval(testInput(:,jj),trainInput,typeKernel,paramKernel) + weightVectorKlms1'*testInput(:,jj) + biasTermKlms1;
        end
        err = testTarget - y_te;
        testMseKlms1(mc) = mean(err.^2);
        %=========end of KLMS 1================

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %               RN
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        [expansionCoefficientRn] = ...
            regularizationNetwork(trainInput,trainTarget,typeKernel,paramKernel,regularizationParameterRn);

        for jj = 1:testSize

            y_te(jj) = expansionCoefficientRn'*...
            ker_eval(testInput(:,jj),trainInput,typeKernel,paramKernel);
        end
        err = testTarget - y_te;
        testMseRn(mc) = mean(err.^2);
        %=========end of RN================

    end%mc

    disp('====================================')
    disp(['kernel param = ',num2str(paramKernel)]);
    disp('<<RN')
    mseMean = mean(testMseRn);
    mseStd = std(testMseRn);
    disp([num2str(mseMean),'+/-',num2str(mseStd)]);

    disp('<<KLMS1')
    mseMean = mean(testMseKlms1);
    mseStd = std(testMseKlms1);
    disp([num2str(mseMean),'+/-',num2str(mseStd)]);

    disp('<<LMS1')
    mseMean = mean(testMseLms1);
    mseStd = std(testMseLms1);
    disp([num2str(mseMean),'+/-',num2str(mseStd)]);

    disp('====================================')

end