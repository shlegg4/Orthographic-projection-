import SwiftUI

struct Point{
    var x : Float = 0
    var y : Float = 0
    init(x : Float,y : Float){
        self.x = x
        self.y = y
    }
}

struct vector{
    var x : Float = 0
    var y : Float = 0
    var z : Float = 0
    var point : Point = Point(x: 0, y: 0)
    
    init(x:Float,y:Float,z:Float){
        self.x = x
        self.y = y
        self.z = z
    }
}




struct triangle{
    var norm : vector
    var posVec1 : vector
    var posVec2 : vector
    var posVec3 : vector
    
    init(normX : Float, normY : Float, normZ : Float, posVec1X : Float, posVec1Y : Float, posVec1Z : Float, posVec2X : Float, posVec2Y : Float, posVec2Z : Float, posVec3X : Float, posVec3Y : Float, posVec3Z : Float){
        self.norm = vector(x: normX,y: normY,z: normZ)
        self.posVec1 = vector(x: posVec1X,y: posVec1Y,z: posVec1Z)
        self.posVec2 = vector(x: posVec2X,y: posVec2Y,z: posVec2Z)
        self.posVec3 = vector(x: posVec3X,y: posVec3Y,z: posVec3Z)
    }
    
    
}
