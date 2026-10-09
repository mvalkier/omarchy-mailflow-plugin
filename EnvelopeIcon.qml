import QtQuick
import QtQuick.Shapes
import qs.Commons

// The envelope in the bar, drawn rather than taken from the Nerd Font: a glyph at
// twice the text size also gets a stroke twice as thick and looks bold next to other
// bar icons. The stroke here matches those icons at Style.space(14): 1.5 on a 24-unit
// box.
//
//   filled: false   outlined (no unread mail; red on a fault, the colour comes from the widget)
//   filled: true    filled, flap cut out in the bar background (unread mail)
Item {
  id: root

  property real iconSize: Style.font.body * 2
  property color color: Color.foreground
  property color backdrop: Color.bar.background
  property bool filled: false

  readonly property real stroke: Style.space(14) * 1.5 / 24 * 24 / root.iconSize

  implicitWidth: iconSize
  implicitHeight: iconSize

  // Separate Shapes rather than several ShapePaths in one Shape: inside a single Shape
  // the filled envelope ended up on top of the flap (even a bright green flap stayed
  // invisible). The stacking order of items is guaranteed.
  Item {
    width: 24
    height: 24
    scale: root.iconSize / 24
    transformOrigin: Item.TopLeft
    layer.enabled: true
    layer.samples: 4

    // Envelope.
    Shape {
      anchors.fill: parent
      antialiasing: true
      ShapePath {
        fillColor: root.filled ? root.color : "transparent"
        strokeColor: root.color
        strokeWidth: root.stroke
        joinStyle: ShapePath.RoundJoin
        PathRectangle {
          x: 2; y: 5.5
          width: 20; height: 13
          radius: 1.8
        }
      }
    }

    // Flap. When filled, a cut-out in the bar background, slightly thicker than the
    // stroke: an equally thin cut-out disappears in the anti-aliasing of the fill.
    Shape {
      anchors.fill: parent
      antialiasing: true
      ShapePath {
        fillColor: "transparent"
        strokeColor: root.filled ? root.backdrop : root.color
        strokeWidth: root.filled ? root.stroke * 1.6 : root.stroke
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        startX: 3; startY: 7
        PathLine { x: 12; y: 12.5 }
        PathLine { x: 21; y: 7 }
      }
    }
  }
}
