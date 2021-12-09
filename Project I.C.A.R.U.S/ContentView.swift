//
//  ContentView.swift
//  Project I.C.A.R.U.S
//
//  Created by Samuel Legg on 30/11/2021.
//

import SwiftUI



struct ContentView: View {
    
    @State var pitch : Float = 0
    @State var roll : Float = 0
    @State var yaw : Float = 0
    @State var scale : Float = 1
    @State var url : String = ""
    @State var xTranslate : Float = 0
    @State var yTranslate : Float = 0
    
    @State var Triangles : [triangle] = []
    @State var pointsX : [Float] = []
    @State var pointsY : [Float] = []
    @State var pointsZ : [Float] = []
    
    
    
    
    @State var point : (Double,Double) = (0,0)
    var body: some View {
        
        HStack{
            
            Canvas { context, size in
                
                    for tri in Triangles{
                        context.stroke(Path{path in
                            path.move(to: CGPoint(x: Double(tri.posVec1.point.x + xTranslate), y:  Double(tri.posVec1.point.y + yTranslate)))
                            path.addLine(to: CGPoint(x: Double(tri.posVec2.point.x + xTranslate), y: Double(tri.posVec2.point.y + yTranslate)))
                            path.addLine(to: CGPoint(x: Double(tri.posVec3.point.x + xTranslate), y: Double(tri.posVec3.point.y + yTranslate)))
                            path.closeSubpath()
                            
                        }, with: .color(.white),lineWidth: 0.25)
                            
                                
                            }

               
            }
            .frame(width: 400, height: 400)
            .border(Color.blue)

            VStack{
                TextField("x:", value :$xTranslate , format: .number)
                TextField("y:", value :$yTranslate , format: .number)
                TextField("pitch:", value :$pitch , format: .number).onSubmit {
                    AdjustPoints()
                }
                TextField("roll:", value :$roll , format: .number).onSubmit {
                    AdjustPoints()
                }
                TextField("yaw:", value :$yaw , format: .number).onSubmit {
                    AdjustPoints()
            }
                TextField("scale:", value :$scale , format: .number).onSubmit {
                    AdjustPoints()
            }
                TextField("URL",text: $url).onSubmit {
                    loadFile()
                }
                
        }
    }
}
    func AdjustPoints(){
        let projectionMatrix = orthographicProjection(pitch: pitch, roll: roll, yaw: yaw,scale : scale)
        let device = MTLCreateSystemDefaultDevice()
        let projector = MetalProjector(device: device!)
        projector.FillBuffers(arrX: pointsX, arrY: pointsY, arrZ: pointsZ, scaX1: projectionMatrix[0,0], scaY1: projectionMatrix[0,1], scaZ1: projectionMatrix[0,2], scaX2: projectionMatrix[1,0], scaY2: projectionMatrix[1,1], scaZ2: projectionMatrix[1,2])
        projector.SendComputeCommand()
        projector.ReturnXYList(tri: &Triangles)
    }
    func loadFile(){
        
        let file = self.url //this is the file. we will write to and read from it

        if let dir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {

            let fileURL = dir.appendingPathComponent(file)


            //reading
            
                var bytes = [uint8]()
                if let data = NSData(contentsOf: fileURL){
                    var buffer = [uint8](repeating: 0, count: data.length)
                    data.getBytes(&buffer,length:data.length)
                    bytes = buffer
                }
                let numberOftris : UInt32 = UInt32(bytes[83])<<24|UInt32(bytes[82])<<16|UInt32(bytes[81])<<8|UInt32(bytes[80])
                
                for n in 0..<numberOftris{
                    
                    let x = 84 + 50*Int(n)
                    var vals: [Float] = []
                    for i in 0..<12{
                        let index = x + 4*i
                        let valuebuff = UInt32(bytes[index+3])<<24|UInt32(bytes[index+2])<<16|UInt32(bytes[index+1])<<8|UInt32(bytes[index])
                        let value = Float32(bitPattern: valuebuff)
                        if((i%3) == 0){
                            vals.append(value)
                            
                        }
                        if(((i-1)%3) == 0){
                            vals.append(value)
                            
                        }
                        if(((i-2)%3) == 0){
                            vals.append(value)
                            
                        }
                        
                    }
                    self.Triangles.append(triangle(normX: vals[0], normY: vals[1], normZ: vals[2], posVec1X: vals[3], posVec1Y: vals[4], posVec1Z: vals[5], posVec2X: vals[6], posVec2Y: vals[7], posVec2Z: vals[8], posVec3X: vals[9], posVec3Y: vals[10], posVec3Z: vals[11]))
                    
                    self.pointsX.append(self.Triangles[self.Triangles.endIndex-1].posVec1.x)
                    self.pointsX.append(self.Triangles[self.Triangles.endIndex-1].posVec2.x)
                    self.pointsX.append(self.Triangles[self.Triangles.endIndex-1].posVec3.x)
                    
                    self.pointsY.append(self.Triangles[self.Triangles.endIndex-1].posVec1.y)
                    self.pointsY.append(self.Triangles[self.Triangles.endIndex-1].posVec2.y)
                    self.pointsY.append(self.Triangles[self.Triangles.endIndex-1].posVec3.y)
                    
                    self.pointsZ.append(self.Triangles[self.Triangles.endIndex-1].posVec1.z)
                    self.pointsZ.append(self.Triangles[self.Triangles.endIndex-1].posVec2.z)
                    self.pointsZ.append(self.Triangles[self.Triangles.endIndex-1].posVec3.z)
                    
                    
//                    print(self.pointsX.description)
//                    print(self.pointsY.description)
//                    print(self.pointsZ.description)
                }
                
                
            }
        
            
            
        }
            
        
    
        
        
    
    
    
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
