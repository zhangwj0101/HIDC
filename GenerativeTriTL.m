% function [Results, Gt, F1, Fs2, Fs3, Ft2, Ft3] = GenerativeTriTL(Train_Data,Test_Data,Parameter_Setting)
function [Results, pzd_t] = GenerativeTriTL(Train_Data,Test_Data,Parameter_Setting)

% function [Results, pz_d] = TriTL(Train_Data,Test_Data,Parameter_Setting)

% The common program for CD_PLSA, which can deal with multiple classes,
% multiple source domains and multiple target domains

%%%% Input:
% The parameter Train_data stores the file pathes of training data and the
% corresponding labels
% The parameter Test_data stores the file pathes of test data and the
% corresponding labels
% The parameter Parameterfile stores the parameter setting information

%%%% Output
% The variable Results is a matrix with size numIteration x numTarget, where
% numIteration is the number of iterations, numTarget is the number of
% target domains. Results record the detailed results of each iteration.

% The variable pz_d is a matrix with size n x c, where n is the number of
% instances in all target domains, specifically, n = n_1 + ... + nt (n_t is
% the number of instances in t-th target domain), c is the number of
% classes
%
% Note that if you want to deal with large data set, you should set larget
% memory for Matlab. You can set it in the file C:\boot.ini (This may not
% be true in your system), change '/fastdetect' to '/fastdetect /3GB'.
%
% Be good luck for your research, if you have any questions, you can
% contact the email: zhuangfz@ics.ict.ac.cn

%read the parameters
fid=fopen(Parameter_Setting);
numK_1 = str2num(fgetl(fid));
numK_2 = str2num(fgetl(fid));
numK_3 = str2num(fgetl(fid));
numIteration = str2num(fgetl(fid));
numK = numK_1 + numK_2 + numK_3;
fclose(fid);

iscsvread = 0;
fid=fopen(Train_Data);
numSource = str2num(fgetl(fid));
fid1=fopen(fgetl(fid));
A = fgetl(fid1);
B = find(A == ',');
if length(B) == 2
    iscsvread = 1;
end
fclose(fid1);
fclose(fid);

labelset = [];

if iscsvread == 1
    % read source domain data
    fid=fopen(Train_Data);
    numSource = str2num(fgetl(fid));
    TrainX = [];
    TrainY = [];
    numTrain = [];
    for i = 1:numSource
        A = csvread(fgetl(fid));
        B = spconvert(A);
        TrainX = [TrainX B];
        C = textread(fgetl(fid));
        TrainY = [TrainY C'];
        numTrain(1,i) = length(C);
        labelset = union(labelset,C');
        clear A;
        clear B;
        clear C;
    end
    fclose(fid);
    
    % read target domain data
    fid=fopen(Test_Data);
    numTarget = str2num(fgetl(fid));
    TestX = [];
    TestY = [];
%     initialTestY = [];
    numTest = [];
    for i = 1:numTarget
        A = csvread(fgetl(fid));
        B = spconvert(A);
        TestX = [TestX B];
        C = textread(fgetl(fid));
        TestY = [TestY C'];
        numTest(1,i) = length(C);
        labelset = union(labelset,C');
%         E = csvread(fgetl(fid));
%         initialTestY = [initialTestY; E];
        clear A;
        clear B;
        clear C;
        clear E;
    end
    fclose(fid);
else
    % read source domain data
    fid=fopen(Train_Data);
    numSource = str2num(fgetl(fid));
    TrainX = [];
    TrainY = [];
    numTrain = [];
    for i = 1:numSource
        A = load(fgetl(fid));
        B = spconvert(A);
        TrainX = [TrainX B];
        C = textread(fgetl(fid));
        TrainY = [TrainY C'];
        numTrain(1,i) = length(C);
        labelset = union(labelset,C');
        clear A;
        clear B;
        clear C;
    end
    fclose(fid);
    
    % read target domain data
    fid=fopen(Test_Data);
    numTarget = str2num(fgetl(fid));
    TestX = [];
    TestY = [];
%     initialTestY = [];
    numTest = [];
    for i = 1:numTarget
        A = load(fgetl(fid));
        B = spconvert(A);
        TestX = [TestX B];
        C = textread(fgetl(fid));
        TestY = [TestY C'];
        numTest(1,i) = length(C);
        labelset = union(labelset,C');
%         E = load(fgetl(fid));
%         initialTestY = [initialTestY; E];
        clear A;
        clear B;
        clear C;
        clear E;
    end
    fclose(fid);
end

numC = length(labelset);
numFeature = size(TestX,1);

start = 1;
% if numK_3 == 0
%     start = 0;
% end
if start == 1
    DataSetX = [TrainX TestX];
    Learn.Verbosity = 1;
    Learn.Max_Iterations = 20;
    Learn.heldout = .1; % for tempered EM only, percentage of held out data
    Learn.Min_Likelihood_Change = 1;
    Learn.Folding_Iterations = 20; % for TEM only: number of fiolding in iterations
    Learn.TEM = 0; %tempered or not tempered
    [Pw_z,Pz_d,Pd,Li,perp,eta] = pLSA(DataSetX,[],numK_1+numK_2,Learn); %start PLSA
    %xlswrite(strcat('pwz_','common_selected','.xls'),Pw_z);
%     csvwrite(strcat('pzw_','common_selected','.plsa'),Pw_z);
end
%pwy = xlsread(strcat('pwz_','common_selected','.xls'));

%% Following are Initializaitons
% pzw = csvread(strcat('pzw_','common_selected','.plsa'));
pzw = Pw_z;
pwy_a = pzw(:,1:numK_1); % the common topics using the same words
pwy_b_s = []; % the common topics using different words
pwy_b_t = []; % the common topics using different words
for i = 1:numSource
    pwy_b_s = [pwy_b_s, pzw(:,1+numK_1:numK_1+numK_2)];
end
for i = 1:numTarget
    pwy_b_t = [pwy_b_t, pzw(:,1+numK_1:numK_1+numK_2)];
end
% pwy_c_s = []; % different topics using different words
% pwy_c_t = []; % different topics using different words
pwy_c_s = ones(numFeature,numK_3*numSource)/numFeature;
pwy_c_t = ones(numFeature,numK_3*numTarget)/numFeature;
clear pzw;
pdz_s = zeros(sum(numTrain),numC);
for i = 1:size(pdz_s,1)
    pdz_s(i,TrainY(i)) = 1;
end
for i = 1:numSource
    pos = 0;
    if i > 1
        for t = 1:i-1
            pos = pos + numTrain(t);
        end
    end
    if i == 1
        pos = 0;
    end
    for j = 1:numC
        pdz_s(pos+1:pos+numTrain(i),j) = pdz_s(pos+1:pos+numTrain(i),j)/sum(pdz_s(pos+1:pos+numTrain(i),j));
    end
end

% In our paper, pdz_t is assigned as the predicted results by supervised
% classifiers
% The initialization of the target-domain label
pdz_t = zeros(sum(numTest),numC);
flag = 1;
if flag == 1
    w_models = [];
    for i = 1:numSource
        pos = 0;
        if i > 1
            for t = 1:i-1
                pos = pos + numTrain(t);
            end
        end
        if i == 1
            pos = 0;
        end
        TempTrainX = TrainX(:,pos+1:pos+numTrain(i));
        TempTrainY = TrainY(:,pos+1:pos+numTrain(i));
        for v = 1:length(TempTrainY)
            if TempTrainY(v) > 1
                TempTrainY(v) = -1;
            end
        end
        
        TempTrainXY = scale_cols(TempTrainX,TempTrainY);
        fprintf('.....................................\n');
        w00 = zeros(size(TempTrainXY,1),1);
        lambda = exp(linspace(-0.5,6,20));
        wbest = [];
        f1max = -inf;
        for j = 1:length(lambda)
            w_0 = train_cg(TempTrainXY,w00,lambda(j));
            f1 = logProb(TempTrainXY,w_0);
            if f1 > f1max
                f1max = f1;
                wbest = w_0;
                %se_lambda = lambda(j);
            end
        end
        w_models = [w_models wbest];
        clear TempTrainX;
        clear TempTrainY;
        clear TempTrainXY;
    end
%     csvwrite(strcat('model_lg.model'),w_models);
end

TempGt = zeros(size(pdz_t));
% w_models = csvread(strcat('model_lg.model'));
for i = 1:numTarget
    pos = 0;
    if i > 1
        for t = 1:i-1
            pos = pos + numTest(t);
        end
    end
    if i == 1
        pos = 0;
    end
    TempTestX = TestX(:,pos+1:pos+numTest(i));
    for j = 1:numSource
        wbest = w_models(:,j);
        ptemp = 1./(1 + exp(-wbest'*TempTestX));
    end
    TempGt(pos+1:pos+numTest(i),:) = TempGt(pos+1:pos+numTest(i),:) + [(ptemp'+0.5)/2 ((1-ptemp)'+0.5)/2];    
    clear TempTestX;
end
TempGt = TempGt/numSource;
pdz_t = TempGt; % not yet normalize
%% The initialization pyz
pyz_a = ones(numK_1,numC)/numK_1;
pyz_b = ones(numK_2,numC)/numK_2;
pyz_c_s = ones(numK_3,numC*numSource)/numK_3;
pyz_c_t = ones(numK_3,numC*numTarget)/numK_3;

%% the initial accuracy
iter_results = [];
for i = 1:numTarget
    pos = 0;
    if i > 1
        for t = 1:i-1
            pos = pos + numTest(t);
        end
    end
    if i == 1
        pos = 0;
    end
    pzd = pdz_t(pos+1:pos+numTest(i),:);
    nCorrect = 0;
    for j = 1:size(pzd,1)
        [va vi] = max(pzd(j,:));
        if labelset(vi) == TestY(pos+j)
            nCorrect = nCorrect + 1;
        end
    end
    iter_results(1,i+1) = nCorrect/(numTest(i));
    iter_results(1,1) = 0;
end
iter_results

% the normalization of pdz_t
for i = 1:numTarget
    pos = 0;
    if i > 1
        for t = 1:i-1
            pos = pos + numTest(t);
        end
    end
    if i == 1
        pos = 0;
    end
    for j = 1:numC
        pdz_t(pos+1:pos+numTest(i),j) = pdz_t(pos+1:pos+numTest(i),j)/sum(pdz_t(pos+1:pos+numTest(i),j));
    end
end

pzr_s = ones(1,numC*numSource)/numC;
pzr_t = ones(1,numC*numTarget)/numC;
pr = ones(1,numSource+numTarget)/(numSource+numTarget);

for i = 1:numSource
    pos = 0;
    if i > 1
        for t = 1:i-1
            pos = pos + numTrain(t);
        end
    end
    if i == 1
        pos = 0;
    end
    pr(i) = sum(sum(TrainX(:,pos+1:pos+numTrain(i))));
end
for i = 1:numTarget
    pos = 0;
    if i > 1
        for t = 1:i-1
            pos = pos + numTest(t);
        end
    end
    if i == 1
        pos = 0;
    end
    pr(numSource+i) = sum(sum(TestX(:,pos+1:pos+numTest(i))));
end
pr = pr/sum(pr);
%% stepLen
stepLen = 1000;
% fprintf('the 0 iteration,the value of objective is %g\n',fvalue);
%% Start to interate
% update all variables 
% pwy_a; pwy_b_s; pwy_b_t; pwy_c_s; pwy_c_t; pdz_s; pdz_t; 
% pyz_a; pyz_b; pyz_c_s; pyz_c_t; pzr_s; pzr_t; pr;
for iterID = 1:numIteration
    
    % update pwy_a; pwy_b_s; pwy_b_t; pwy_c_s; pwy_c_t;
    temp_pwy_a = zeros(size(pwy_a));
    temp_pwy_b_s = [];
    temp_pwy_b_t = [];
    temp_pwy_c_s = [];
    temp_pwy_c_t = [];    
    % update pdz_t; 
    temp_pdz_t = [];    
    % update pzr_s; pzr_t; pr
    temp_pzr_s = [];
    temp_pzr_t = [];
    temp_pr = [];
    for i = 1:numSource
        pos = 0;
        if i > 1
            for t = 1:i-1
                pos = pos + numTrain(t);
            end
        end
        if i == 1
            pos = 0;
        end
        A = pyz_a;
        for j = 1:numC
            A(:,j) = A(:,j)*pzr_s(1,j+(i-1)*numC);
        end
        
        tempsum2 = pwy_a*A*pdz_s(pos+1:pos+numTrain(i),:)';
        tempsum2 = tempsum2*pr(i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        temp_pwy_a = temp_pwy_a + pwy_a.*(MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,pdz_s(pos+1:pos+numTrain(i),:),stepLen)*A'*pr(i));
        I = sum(MatrixProduce(pwy_a',MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,pdz_s(pos+1:pos+numTrain(i),:),stepLen),stepLen).*pyz_a)*pr(i);
        
        %%-----------------%%
        A = pyz_b;
        for j = 1:numC
            A(:,j) = A(:,j)*pzr_s(1,j+(i-1)*numC);
        end
        
        tempsum2 = pwy_b_s(:,(i-1)*numK_2+1:i*numK_2)*A*pdz_s(pos+1:pos+numTrain(i),:)';
        tempsum2 = tempsum2*pr(i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        B = pwy_b_s(:,(i-1)*numK_2+1:i*numK_2).*(MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,pdz_s(pos+1:pos+numTrain(i),:),stepLen)*A'*pr(i));
        temp_pwy_b_s = [temp_pwy_b_s B];
        I = I + sum(MatrixProduce(pwy_b_s(:,(i-1)*numK_2+1:i*numK_2)',MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,pdz_s(pos+1:pos+numTrain(i),:),stepLen),stepLen).*pyz_b)*pr(i);
        
        A = pyz_c_s(:,(i-1)*numC+1:i*numC);
        for j = 1:numC
            A(:,j) = A(:,j)*pzr_s(1,j+(i-1)*numC);
        end
        
        tempsum2 = pwy_c_s(:,(i-1)*numK_3+1:i*numK_3)*A*pdz_s(pos+1:pos+numTrain(i),:)';
        tempsum2 = tempsum2*pr(i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        B = pwy_c_s(:,(i-1)*numK_3+1:i*numK_3).*(MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,pdz_s(pos+1:pos+numTrain(i),:),stepLen)*A'*pr(i));
        temp_pwy_c_s = [temp_pwy_c_s B];   
        I = I + sum(MatrixProduce(pwy_c_s(:,(i-1)*numK_3+1:i*numK_3)',MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,pdz_s(pos+1:pos+numTrain(i),:),stepLen),stepLen).*pyz_c_s(:,(i-1)*numC+1:i*numC))*pr(i);
        temp_pzr_s = [temp_pzr_s I]; 
        temp_pr = [temp_pr sum(I)];
    end
    for i = 1:numTarget
        pos = 0;
        if i > 1
            for t = 1:i-1
                pos = pos + numTest(t);
            end
        end
        if i == 1
            pos = 0;
        end
        A = pyz_a;
        for j = 1:numC
            A(:,j) = A(:,j)*pzr_t(1,j+(i-1)*numC);
        end        
        
        tempsum2 = pwy_a*A*pdz_t(pos+1:pos+numTest(i),:)';
        tempsum2 = tempsum2*pr(numSource+i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        temp_pwy_a = temp_pwy_a + pwy_a.*(MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,pdz_t(pos+1:pos+numTest(i),:),stepLen)*A'*pr(numSource+i));
        H = (MatrixProduce([TestX(:,pos+1:pos+numTest(i))./tempsum2]',pwy_a,stepLen)*A*pr(numSource+i));
        I = sum(MatrixProduce(pwy_a',MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,pdz_t(pos+1:pos+numTest(i),:),stepLen),stepLen).*pyz_a)*pr(numSource+i);
        %%-----------------%%
        A = pyz_b;
        for j = 1:numC
            A(:,j) = A(:,j)*pzr_t(1,j+(i-1)*numC);
        end
        
        tempsum2 = pwy_b_t(:,(i-1)*numK_2+1:i*numK_2)*A*pdz_t(pos+1:pos+numTest(i),:)';
        tempsum2 = tempsum2*pr(numSource+i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        B = pwy_b_t(:,(i-1)*numK_2+1:i*numK_2).*(MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,pdz_t(pos+1:pos+numTest(i),:),stepLen)*A'*pr(numSource+i));
        temp_pwy_b_t = [temp_pwy_b_t B];
        H = H + (MatrixProduce([TestX(:,pos+1:pos+numTest(i))./tempsum2]',pwy_b_t(:,(i-1)*numK_2+1:i*numK_2),stepLen)*A*pr(numSource+i));
        I = I + sum(MatrixProduce(pwy_b_t(:,(i-1)*numK_2+1:i*numK_2)',MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,pdz_t(pos+1:pos+numTest(i),:),stepLen),stepLen).*pyz_b)*pr(numSource+i);
                
        A = pyz_c_t(:,(i-1)*numC+1:i*numC);
        for j = 1:numC
            A(:,j) = A(:,j)*pzr_t(1,j+(i-1)*numC);
        end
        
        tempsum2 = pwy_c_t(:,(i-1)*numK_3+1:i*numK_3)*A*pdz_t(pos+1:pos+numTest(i),:)';
        tempsum2 = tempsum2*pr(numSource+i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        B = pwy_c_t(:,(i-1)*numK_3+1:i*numK_3).*(MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,pdz_t(pos+1:pos+numTest(i),:),stepLen)*A'*pr(numSource+i));
        temp_pwy_c_t = [temp_pwy_c_t B];
        H = H + (MatrixProduce([TestX(:,pos+1:pos+numTest(i))./tempsum2]',pwy_c_t(:,(i-1)*numK_3+1:i*numK_3),stepLen)*A*pr(numSource+i));
        H = pdz_t(pos+1:pos+numTest(i),:).*H;
        temp_pdz_t = [temp_pdz_t; H];
        I = I + sum(MatrixProduce(pwy_c_t(:,(i-1)*numK_3+1:i*numK_3)',MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,pdz_t(pos+1:pos+numTest(i),:),stepLen),stepLen).*pyz_c_t(:,(i-1)*numC+1:i*numC))*pr(numSource+i);
        temp_pzr_t = [temp_pzr_t I]; 
        temp_pr = [temp_pr sum(I)];
    end    
    
    % update pyz_a; pyz_b; pyz_c_s; pyz_c_t;
    temp_pyz_a = zeros(size(pyz_a));
    temp_pyz_b = zeros(size(pyz_b));
    temp_pyz_c_s = [];
    temp_pyz_c_t = [];
    for i = 1:numSource
        pos = 0;
        if i > 1
            for t = 1:i-1
                pos = pos + numTrain(t);
            end
        end
        if i == 1
            pos = 0;
        end
        A = pdz_s(pos+1:pos+numTrain(i),:);
        for j = 1:numC
            A(:,j) = A(:,j)*pzr_s(1,j+(i-1)*numC);
        end
        
        tempsum2 = pwy_a*pyz_a*A';
        tempsum2 = tempsum2*pr(i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        temp_pyz_a = temp_pyz_a + pyz_a.*(MatrixProduce(pwy_a',MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,A,stepLen),stepLen)*pr(i));
        
        %%-----------------%%
        tempsum2 = pwy_b_s(:,(i-1)*numK_2+1:i*numK_2)*pyz_b*A';
        tempsum2 = tempsum2*pr(i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        temp_pyz_b = temp_pyz_b + pyz_b.*(MatrixProduce(pwy_b_s(:,(i-1)*numK_2+1:i*numK_2)',MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,A,stepLen),stepLen)*pr(i));
        
        tempsum2 = pwy_c_s(:,(i-1)*numK_3+1:i*numK_3)*pyz_c_s(:,(i-1)*numC+1:i*numC)*A';
        tempsum2 = tempsum2*pr(i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        B = pyz_c_s(:,(i-1)*numC+1:i*numC).*(MatrixProduce(pwy_c_s(:,(i-1)*numK_3+1:i*numK_3)',MatrixProduce(TrainX(:,pos+1:pos+numTrain(i))./tempsum2,A,stepLen),stepLen)*pr(i));
        temp_pyz_c_s = [temp_pyz_c_s B];
    end
    for i = 1:numTarget
        pos = 0;
        if i > 1
            for t = 1:i-1
                pos = pos + numTest(t);
            end
        end
        if i == 1
            pos = 0;
        end
        A = pdz_t(pos+1:pos+numTest(i),:);
        for j = 1:numC
            A(:,j) = A(:,j)*pzr_t(1,j+(i-1)*numC);
        end
        tempsum2 = pwy_a*pyz_a*A';
        tempsum2 = tempsum2*pr(numSource+i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        temp_pyz_a = temp_pyz_a + pyz_a.*(MatrixProduce(pwy_a',MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,A,stepLen),stepLen)*pr(numSource+i));
        
        %%-----------------%%
        tempsum2 = pwy_b_t(:,(i-1)*numK_2+1:i*numK_2)*pyz_b*A';
        tempsum2 = tempsum2*pr(numSource+i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        temp_pyz_b = temp_pyz_b + pyz_b.*(MatrixProduce(pwy_b_t(:,(i-1)*numK_2+1:i*numK_2)',MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,A,stepLen),stepLen)*pr(numSource+i));
        
        tempsum2 = pwy_c_t(:,(i-1)*numK_3+1:i*numK_3)*pyz_c_t(:,(i-1)*numC+1:i*numC)*A';
        tempsum2 = tempsum2*pr(numSource+i);
        [xs ys] = find(tempsum2 < 10^(-20));
        for q = 1:size(xs,1)
            tempsum2(xs(q,1),ys(q,1)) = 1;
        end
        B = pyz_c_t(:,(i-1)*numC+1:i*numC).*(MatrixProduce(pwy_c_t(:,(i-1)*numK_3+1:i*numK_3)',MatrixProduce(TestX(:,pos+1:pos+numTest(i))./tempsum2,A,stepLen),stepLen)*pr(numSource+i));
        temp_pyz_c_t = [temp_pyz_c_t B];
    end    
     
    % normalize all the variables
    pwy_a = temp_pwy_a;
    pwy_b_s = temp_pwy_b_s; 
    pwy_b_t = temp_pwy_b_t; 
    pwy_c_s = temp_pwy_c_s; 
    pwy_c_t = temp_pwy_c_t; 
    % pdz_s = temp_pdz_s; 
    pdz_t = temp_pdz_t; 
    pyz_a = temp_pyz_a; 
    pyz_b = temp_pyz_b; 
    pyz_c_s = temp_pyz_c_s; 
    pyz_c_t = temp_pyz_c_t; 
    pzr_s = temp_pzr_s; 
    pzr_t = temp_pzr_t; 
    pr = temp_pr;
    
    for t = 1:numK_1
        pwy_a(:,t) = pwy_a(:,t)/sum(pwy_a(:,t));
    end
    for t = 1:numC
        pyz_a(:,t) = pyz_a(:,t)/sum(pyz_a(:,t));
        pyz_b(:,t) = pyz_b(:,t)/sum(pyz_b(:,t));
    end
    pr = pr/sum(pr);
    for t = 1:numK_2*numSource
        pwy_b_s(:,t) = pwy_b_s(:,t)/sum(pwy_b_s(:,t));
    end
    for t = 1:numK_3*numSource
        pwy_c_s(:,t) = pwy_c_s(:,t)/sum(pwy_c_s(:,t));
    end
    for t = 1:numC*numSource
        pyz_c_s(:,t) = pyz_c_s(:,t)/sum(pyz_c_s(:,t));
    end
    for t = 1:numK_2*numTarget
        pwy_b_t(:,t) = pwy_b_t(:,t)/sum(pwy_b_t(:,t));
    end
    for t = 1:numK_3*numTarget
        pwy_c_t(:,t) = pwy_c_t(:,t)/sum(pwy_c_t(:,t));
    end
    for t = 1:numC*numTarget
        pyz_c_t(:,t) = pyz_c_t(:,t)/sum(pyz_c_t(:,t));
    end
    for i = 1:numTarget
        pos = 0;
        if i > 1
            for t = 1:i-1
                pos = pos + numTest(t);
            end
        end
        if i == 1
            pos = 0;
        end
        for t = 1:numC
            pdz_t(pos+1:pos+numTest(i),t) = pdz_t(pos+1:pos+numTest(i),t)/sum(pdz_t(pos+1:pos+numTest(i),t));
        end
    end    
    for i = 1:numSource
        pzr_s(1,(i-1)*numC+1:i*numC) = pzr_s(1,(i-1)*numC+1:i*numC)/sum(pzr_s(1,(i-1)*numC+1:i*numC));
    end
    for i = 1:numTarget
        pzr_t(1,(i-1)*numC+1:i*numC) = pzr_t(1,(i-1)*numC+1:i*numC)/sum(pzr_t(1,(i-1)*numC+1:i*numC));
    end
    
    %%%%%% The output results
    pzd_t = [];
    for i = 1:numTarget
        A = pdz_t(pos+1:pos+numTest(i),:);
        for t = 1:numC
            A(:,t) = A(:,t)*pzr_t(1,(i-1)*numC+t);
        end
        A = A*pr(numSource+i);
        pzd_t = [pzd_t; A];
    end
    iter_results(iterID+1,1) = iterID;
    for i = 1:numTarget
        pos = 0;
        if i > 1
            for t = 1:i-1
                pos = pos + numTest(t);
            end
        end
        if i == 1
            pos = 0;
        end
        pzd = pzd_t(pos+1:pos+numTest(i),:);
        nCorrect = 0;
        for j = 1:size(pzd,1)
            [va vi] = max(pzd(j,:));
            if labelset(vi) == TestY(pos+j)
                nCorrect = nCorrect + 1;
            end
        end
        iter_results(iterID+1,i+1) = nCorrect/(numTest(i));
    end
    iter_results(iterID+1,:)      
    pr
end
%% output
iter_results
Results = iter_results;