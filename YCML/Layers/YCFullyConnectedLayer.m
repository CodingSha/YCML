//
//  YCFullyConnectedLayer.m
//  YCML
//
//  Created by Ioannis (Yannis) Chatzikonstantinou on 11/10/15.
//  Copyright © 2015 Ioannis (Yannis) Chatzikonstantinou. All rights reserved.
//
// This file is part of YCML.
//
// YCML is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// YCML is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with YCML.  If not, see <http://www.gnu.org/licenses/>.

#import "YCFullyConnectedLayer.h"
@import YCMatrix;

// I: Input size
// O: Output size
// S: Sample count

@implementation YCFullyConnectedLayer

+ (instancetype)layerWithInputSize:(int)inputSize outputSize:(int)outputSize
{
    return [[self alloc] initWithInputSize:inputSize outputSize:outputSize];
}

- (instancetype)initWithInputSize:(int)inputSize outputSize:(int)outputSize
{
    NSAssert(inputSize > 0 && outputSize > 0,
             @"Input and/or Output sizes are equal to or less than zero");
    self = [super init];
    if (self)
    {
        self.weightMatrix = [Matrix matrixOfRows:inputSize columns:outputSize];
        self.biasVector = [Matrix matrixOfRows:outputSize columns:1];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.weightMatrix = [aDecoder decodeObjectForKey:@"weightMatrix"];
        self.biasVector = [aDecoder decodeObjectForKey:@"biasVector"];
        self.lastActivation = [aDecoder decodeObjectForKey:@"lastActivation"];
        self.L2 = [aDecoder decodeDoubleForKey:@"L2"];
    }
    return self;
}

- (Matrix *)forward:(Matrix *)input
{
    Matrix *output = [self.weightMatrix matrixByTransposingAndMultiplyingWithRight:input]; // (IxO)T * IxS = OxS
    [output addColumn:self.biasVector];
    [self activationFunction:output];
    self.lastActivation = [output copy];
    return output;
}

- (Matrix *)backward:(Matrix *)outputDeltas input:(Matrix *)input
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (NSArray *)gradientsWithInput:(Matrix *)input deltas:(Matrix *)deltas
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (double)regularizationLoss
{
    return [[self.weightMatrix matrixByElementWiseMultiplyWith:self.weightMatrix] sum] * self.L2;
}

- (void)activationFunction:(Matrix *)inputCopy
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (void)activationFunctionGradient:(Matrix *)outputCopy
{
    @throw [NSInternalInconsistencyException initWithFormat:
            @"You must override %@ in subclass %@", NSStringFromSelector(_cmd), [self class]];
}

- (int)inputSize
{
    return self.weightMatrix.rows;
}

- (int)outputSize
{
    return self.weightMatrix.columns;
}

- (id)copyWithZone:(NSZone *)zone
{
    YCFullyConnectedLayer *copy = [super copyWithZone:zone];
    copy.weightMatrix = [self.weightMatrix copy];
    copy.biasVector = [self.biasVector copy];
    copy.L2 = self.L2;
    copy.lastActivation = [self.lastActivation copy];
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.weightMatrix forKey:@"weightMatrix"];
    [aCoder encodeObject:self.biasVector forKey:@"biasVector"];
    [aCoder encodeObject:self.lastActivation forKey:@"lastActivation"];
    [aCoder encodeDouble:self.L2 forKey:@"L2"];
}

@end
