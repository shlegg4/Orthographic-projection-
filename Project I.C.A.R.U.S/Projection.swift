//
//  Projection.swift
//  Project I.C.A.R.U.S
//
//  Created by Samuel Legg on 30/11/2021.
//

import Foundation
import matrixLib
import Metal

func orthographicProjection(pitch:Float,roll:Float,yaw:Float,scale:Float) -> Matrix{
    let matPlane = Matrix(rows: 2, columns: 3, type: .custMatrix, data: [1,0,0,0,1,0])
    let pitchMat = Matrix(rows: 3, columns: 3, type: .custMatrix, data: [cos(pitch),0,sin(pitch),0,1,0,-sin(pitch),0,cos(pitch)])
    let rollMat = Matrix(rows: 3, columns: 3, type: .custMatrix, data: [1,0,0,0,cos(roll),-sin(roll),0,sin(roll),cos(roll)])
    let yawMat = Matrix(rows: 3, columns: 3, type: .custMatrix, data: [cos(yaw),-sin(yaw),0,sin(yaw),cos(yaw),0,0,0,1])
    
    let matPlaneAdj = Matrix.scalar_multiply(matA: Matrix.multiply(matA:Matrix.multiply(matA: Matrix.multiply(matA: matPlane, matB: pitchMat), matB: rollMat),matB:yawMat),scalar: scale)
    return matPlaneAdj
}

class MetalProjector{
    var error : NSError?
    var device : MTLDevice!
    var addFunctionPSO : MTLComputePipelineState!
    var scalarMultiplyFunctionPSO : MTLComputePipelineState!
    var commandQueue : MTLCommandQueue!
    
//    vector input buffers
    var bufferx : MTLBuffer!
    var buffery : MTLBuffer!
    var bufferz : MTLBuffer!
    
// temporary buffers for holding result of scalar multiplication
    var bufferXres : MTLBuffer!
    var bufferYres : MTLBuffer!
    var bufferZres : MTLBuffer!
    var scaX1 : Float = 0
    var scaY1 : Float = 0
    var scaZ1 : Float = 0
    var scaX2 : Float = 0
    var scaY2 : Float = 0
    var scaZ2 : Float = 0
    

    
//      vector output buffers
    var bufferXRes : MTLBuffer!
    var bufferYRes : MTLBuffer!
    
    var arrayLength : Int = 0
    
    
    
    init (device : MTLDevice){
        self.device = device
        let defaultLibrary : MTLLibrary! = self.device.makeDefaultLibrary()
        let addFunction : MTLFunction! = defaultLibrary.makeFunction(name: "add_arrays")
        let scalarMultiplyFunction : MTLFunction! = defaultLibrary.makeFunction(name: "multiply_array_by_scalar")
        self.addFunctionPSO = try! self.device.makeComputePipelineState(function: addFunction)
        self.scalarMultiplyFunctionPSO = try! self.device.makeComputePipelineState(function: scalarMultiplyFunction)
        self.commandQueue = self.device.makeCommandQueue()
        
    }
    func FillBuffers(arrX : [Float], arrY : [Float], arrZ : [Float], scaX1 : Float , scaY1 : Float , scaZ1 : Float,scaX2 : Float , scaY2 : Float , scaZ2 : Float){
        self.arrayLength = arrX.count
        let BufferSize = arrX.count * MemoryLayout<Float>.size
        
            self.bufferx = self.device.makeBuffer(length: BufferSize, options: MTLResourceOptions.storageModeShared)
            self.buffery = self.device.makeBuffer(length: BufferSize, options: MTLResourceOptions.storageModeShared)
            self.bufferz = self.device.makeBuffer(length: BufferSize, options: MTLResourceOptions.storageModeShared)
        
        self.bufferXres = self.device.makeBuffer(length: BufferSize, options: MTLResourceOptions.storageModeShared)
        self.bufferYres = self.device.makeBuffer(length: BufferSize, options: MTLResourceOptions.storageModeShared)
        self.bufferZres = self.device.makeBuffer(length: BufferSize, options: MTLResourceOptions.storageModeShared)
            self.bufferXRes = self.device.makeBuffer(length: BufferSize, options: MTLResourceOptions.storageModeShared)
            self.bufferYRes = self.device.makeBuffer(length: BufferSize, options: MTLResourceOptions.storageModeShared)
        self.scaX1 = scaX1
        self.scaY1 = scaY1
        self.scaZ1 = scaZ1
        self.scaX2 = scaX2
        self.scaY2 = scaY2
        self.scaZ2 = scaZ2


        
        
        self.loadData(buffer: self.bufferx, arr: arrX)
        self.loadData(buffer: self.buffery, arr: arrY)
        self.loadData(buffer: self.bufferz, arr: arrZ)
    }
    func loadData(buffer : MTLBuffer , sca : Float){
        let dataPTR = buffer.contents().bindMemory(to: Float.self, capacity: 1)
        dataPTR[0] = sca
    }
    
    func loadData(buffer : MTLBuffer,arr : [Float]){
        let dataPtr = buffer.contents().bindMemory(to: Float.self, capacity: arr.count)
        for i in 0 ..< arr.count {
            dataPtr[i] = arr[i]
        }
    }
    
    func encodeScalarCommands(computeEncoder : MTLComputeCommandEncoder,buffer : MTLBuffer, Sca : inout Float, bufferRes : MTLBuffer?){
        computeEncoder.setComputePipelineState(self.scalarMultiplyFunctionPSO)
        computeEncoder.setBuffer(buffer, offset: 0, index: 0)
        computeEncoder.setBytes(&Sca, length: MemoryLayout<Float>.size, index: 1)
        computeEncoder.setBuffer(bufferRes, offset: 0, index: 2)
        let gridSize : MTLSize = MTLSizeMake(self.arrayLength, 1, 1)
        
        var threadGroupSizeInt : Int = self.scalarMultiplyFunctionPSO.maxTotalThreadsPerThreadgroup
        
        if(threadGroupSizeInt > self.arrayLength){
            threadGroupSizeInt = self.arrayLength
        }
        
        let threadGroupSize : MTLSize = MTLSizeMake(threadGroupSizeInt, 1, 1)
        
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
    }
    
    func encodeAddcommands(computeEncoder : MTLComputeCommandEncoder,bufferA : MTLBuffer, bufferB : MTLBuffer, bufferC : MTLBuffer,bufferRes : MTLBuffer){
        computeEncoder.setComputePipelineState(self.addFunctionPSO)
        computeEncoder.setBuffer(bufferA, offset: 0, index: 0)
        computeEncoder.setBuffer(bufferB, offset: 0, index: 1)
        computeEncoder.setBuffer(bufferC, offset: 0, index: 2)
        computeEncoder.setBuffer(bufferRes, offset: 0, index: 3)
        
        let gridSize : MTLSize = MTLSizeMake(arrayLength, 1, 1)
       
               var threadGroupSizeInt : Int = self.addFunctionPSO.maxTotalThreadsPerThreadgroup
       
               if(threadGroupSizeInt > arrayLength){
                   threadGroupSizeInt = arrayLength
               }
       
               let threadGroupSize : MTLSize = MTLSizeMake(threadGroupSizeInt, 1, 1)
       
               computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
        
        
    }
    
    
    func SendComputeCommand(){
        
        let commandBuffer: MTLCommandBuffer? = commandQueue.makeCommandBuffer()
        assert(commandBuffer != nil, "Command buffer = nil")
        
        let computeEncoder : MTLComputeCommandEncoder? = commandBuffer?.makeComputeCommandEncoder()
        assert(computeEncoder != nil, " Compute encoder = nil")
        
        self.encodeScalarCommands(computeEncoder: computeEncoder!,buffer: self.bufferx,Sca: &self.scaX1,bufferRes: self.bufferXres)
        self.encodeScalarCommands(computeEncoder: computeEncoder!,buffer: self.buffery,Sca: &self.scaY1,bufferRes: self.bufferYres)
        self.encodeScalarCommands(computeEncoder: computeEncoder!,buffer: self.bufferz,Sca: &self.scaZ1,bufferRes: self.bufferZres)
        self.encodeAddcommands(computeEncoder: computeEncoder!, bufferA: self.bufferXres, bufferB: self.bufferYres, bufferC: self.bufferZres, bufferRes: self.bufferXRes)
        self.encodeScalarCommands(computeEncoder: computeEncoder!,buffer: self.bufferx,Sca: &self.scaX2,bufferRes: self.bufferXres)
        self.encodeScalarCommands(computeEncoder: computeEncoder!,buffer: self.buffery,Sca: &self.scaY2,bufferRes: self.bufferYres)
        self.encodeScalarCommands(computeEncoder: computeEncoder!,buffer: self.bufferz,Sca: &self.scaZ2,bufferRes: self.bufferZres)
        self.encodeAddcommands(computeEncoder: computeEncoder!, bufferA: self.bufferXres, bufferB: self.bufferYres, bufferC: self.bufferZres, bufferRes: self.bufferYRes)
        computeEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        
    }
    
    func ReturnXYList(tri : inout [triangle]){
        let Xres = self.bufferXRes.contents().bindMemory(to: Float.self, capacity: self.bufferx.allocatedSize/MemoryLayout<Float>.size)
        let Yres = self.bufferYRes.contents().bindMemory(to: Float.self, capacity: self.bufferx.allocatedSize/MemoryLayout<Float>.size)
        var j = 0
        for i in 0..<self.arrayLength{
            
            if ((i) % 3 == 0){
                tri[j].posVec1.point.x = Xres[i]
                tri[j].posVec1.point.y = Yres[i]
            }
            if ((i-1) % 3 == 0){
                tri[j].posVec2.point.x = Xres[i]
                tri[j].posVec2.point.y = Yres[i]
            }
            if ((i-2) % 3 == 0){
                tri[j].posVec3.point.x = Xres[i]
                tri[j].posVec3.point.y = Yres[i]
                j += 1
            }
            
        }
        
    }
}







