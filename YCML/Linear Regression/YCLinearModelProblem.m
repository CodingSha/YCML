//
//  YCLinearModelProblem.m
//  YCML
//
//  Created by Ioannis Chatzikonstantinou on 12/12/16.
//  Copyright © 2016 Yannis Chatzikonstantinou. All rights reserved.
//

#import "YCLinearModelProblem.h"
#import "YCLinRegModel.h"
@import YCMatrix;

@implementation YCLinearModelProblem
{
    Matrix *_parameterVector;
    Matrix *_inputMatrix;
    Matrix *_outputMatrix;
}

- (instancetype)initWithInputMatrix:(Matrix *)input
                       outputMatrix:(Matrix *)output
                              model:(YCLinRegModel *)model
{
    self = [super init];
    if (self)
    {
        self->_inputMatrix = input;
        self->_outputMatrix = output;
        self->_model = model;
    }
    return self;
}

-(Matrix *)initialValuesRangeHint
{
    int parameterCount = [self parameterCount];
    Matrix *minValues = [Matrix matrixOfRows:parameterCount columns:1 value:-0.1];
    Matrix *maxValues = [Matrix matrixOfRows:parameterCount columns:1 value:0.1];
    return [minValues appendColumn:maxValues];
}

- (Matrix *)parameterBounds
{
    return nil;
}

- (int)parameterCount
{
    return [self weightParameterCount] + self->_outputMatrix.rows;
}

- (int)objectiveCount
{
    return 1;
}

- (int)constraintCount
{
    return 0;
}

- (Matrix *)evaluateWithParameters:(Matrix *)parameters
{
    self.model.theta = [self thetaWithParameters:parameters];
    Matrix *residual      = [self.model activateWithMatrix:self->_inputMatrix];
    
    // calculate sum-of-squares error
    [residual subtract:self->_outputMatrix];
    [residual applyFunction:^double(double value) {
        return 0.5*value*value;
    }];
    
    // calculate regularization term
    int n = self->_outputMatrix->columns;
    int s = self->_outputMatrix->rows;
    // Ignore bias (last element)
    Matrix *weights = [parameters matrixWithRowsInRange:NSMakeRange(0, [self weightParameterCount] - 1)];
    [weights elementWiseMultiply:weights];
    double ws2 = [weights sum];
    
    // add and return
    double cost = [residual sum] / (n * s) + self.lambda * ws2/n;
    return [Matrix matrixOfRows:1 columns:1 value:cost];
}

- (Matrix *)derivativeWithParameters:(Matrix *)parameters
{
    int n                   = self->_outputMatrix->columns;
    self.model.theta = [self thetaWithParameters:parameters];
    Matrix *residual      = [self.model activateWithMatrix:self->_inputMatrix];
    
    // calculate derivative
    [residual subtract:self->_outputMatrix];
    Matrix *gradients = [residual matrixByTransposingAndMultiplyingWithLeft:self->_inputMatrix];
    [gradients multiplyWithScalar:1.0/n];
    
    // add regularization term
    Matrix *scaledWeights = [self.model.theta matrixByMultiplyingWithScalar:self.lambda];
    scaledWeights = [scaledWeights removeRow:scaledWeights.rows - 1];
    [scaledWeights multiplyWithScalar:1.0/n];
    
    [gradients add:scaledWeights];
    Matrix *biases = [[residual meansOfRows] matrixByTransposing];
    [biases multiplyWithScalar:1.0/n];
    gradients = [gradients appendRow:biases];
    
    return [self parametersWithTheta:gradients];
}

- (Matrix *)thetaWithParameters:(Matrix *)parameters
{
    return [Matrix matrixFromArray:parameters->matrix
                                rows:self->_inputMatrix.rows + 1
                             columns:self->_outputMatrix.rows];
}

- (Matrix *)parametersWithTheta:(Matrix *)theta
{
    return [Matrix matrixFromArray:theta->matrix rows:(int)theta.count columns:1];
}

- (int)weightParameterCount
{
    return (int)(self->_inputMatrix.rows * self->_outputMatrix.rows);
}

- (YCEvaluationMode)supportedEvaluationMode
{
    return YCProvidesParallelImplementation;
}

@end
