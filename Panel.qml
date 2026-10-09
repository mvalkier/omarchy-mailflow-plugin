import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

// The panel behind a click on the envelope: total, unread per account, a sign-in tile
// when there is no session, and a tile to the web app. Cards with a thin border and a
// coloured stripe on the left, section headers in capitals.
// All data comes from the bar widget (reading, reason, url); the panel fetches nothing.
Panel {
  id: root
  moduleName: "melkweg.mailflow"
  // The bar widget owns the IPC target; two handlers on the same target are not allowed.
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var reading: null
  property string reason: "unreachable"
  property string url: ""

  readonly property var barIdentity: hostWidget || root
  function switchPanel(direction) {
    return root.bar ? root.bar.switchPanelFrom(root.barIdentity, direction) : false
  }

  readonly property var colors: ({
    panel: "#0f1620", border: "#1a2535", text: "#c8d8e8", muted: "#8aadcc",
    grey: "#6b7280", red: "#f87171"
  })
  readonly property color accent: Color.accent

  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property var accounts: root.reading && root.reason === "" ? (root.reading.accounts || []) : []
  readonly property bool faulty: root.reason !== "" || (root.reading !== null && root.reading.complete !== true)
  readonly property int total: root.reading && root.reason === "" ? root.reading.total : 0

  function faultText() {
    if (root.reason === "login") return "Not signed in"
    if (root.reason !== "") return "MailFlow unreachable"
    return "Counts out of date"
  }

  function timeText() {
    if (!root.reading) return ""
    return Qt.formatTime(new Date(root.reading.time * 1000), "HH:mm")
  }

  // iCloud gets the iCloud logo, everything else an envelope (Nerd Font Material Design).
  function accountGlyph(email) {
    return /@(icloud|me|mac)\.com$/i.test(String(email))
      ? String.fromCodePoint(0xF0038) : String.fromCodePoint(0xF01EE)
  }

  function openWebmail() { if (root.hostWidget) root.hostWidget.openWebmail() }

  component SectionHeader: Text {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    color: root.colors.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    font.bold: true
    font.letterSpacing: 1
  }

  // A card with a border and a stripe on the left. Informational by default: a card
  // that lights up promises that a click leads to that account, and MailFlow has no
  // link to an account or folder. Only the tiles are clickable; `disabled` dims one.
  component Card: Rectangle {
    id: card
    property color stripe: root.colors.grey
    property bool clickable: false
    property bool disabled: false
    default property alias content: inner.data
    signal activated()

    Layout.fillWidth: true
    radius: Style.space(6)
    color: hover.containsMouse && card.clickable && !card.disabled ? Qt.lighter(root.colors.panel, 1.35) : root.colors.panel
    border.width: 1
    border.color: root.colors.border
    opacity: card.disabled ? 0.45 : 1

    Rectangle {
      width: Style.space(3)
      radius: Style.space(3)
      color: card.stripe
      anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    }

    Item {
      id: inner
      anchors {
        fill: parent
        leftMargin: Style.space(16); rightMargin: Style.space(12)
      }
    }

    MouseArea {
      id: hover
      anchors.fill: parent
      hoverEnabled: true
      enabled: card.clickable && !card.disabled
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: card.activated()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function (direction) { root.switchPanel(direction) }

      // No anchors.margins: KeyboardPanel.padding already sets the inset.
      ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Style.space(8)

        RowLayout {
          Layout.fillWidth: true

          // Links to the MailFlow.sh project site.
          Text {
            text: "MailFlow.sh"
            color: titleMouse.containsMouse ? root.accent : root.colors.text
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            font.underline: titleMouse.containsMouse

            MouseArea {
              id: titleMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.close()
                Quickshell.execDetached(["xdg-open", "https://mailflow.sh"])
              }
            }
          }

          Item { Layout.fillWidth: true }

          Text {
            visible: root.reading !== null && root.reason === ""
            text: root.timeText()
            color: root.colors.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Rectangle {
          Layout.fillWidth: true
          visible: root.faulty
          implicitHeight: faultLabel.implicitHeight + Style.space(16)
          radius: Style.space(6)
          color: root.colors.panel
          border.width: 1
          border.color: root.colors.red

          Text {
            id: faultLabel
            anchors {
              left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
              leftMargin: Style.space(12); rightMargin: Style.space(12)
            }
            text: root.faultText()
            color: root.colors.red
            wrapMode: Text.Wrap
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
          }
        }

        SectionHeader { text: "UNREAD"; visible: root.reason === "" }

        Card {
          visible: root.reason === ""
          stripe: root.total > 0 ? root.accent : root.colors.grey
          implicitHeight: totalColumn.implicitHeight + Style.space(26)

          Column {
            id: totalColumn
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Text {
              text: root.total === 0 ? "NO NEW MAIL" : "INBOX"
              color: root.colors.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
            }
            Text {
              text: String(root.total)
              color: root.total > 0 ? root.accent : root.colors.text
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              font.bold: true
            }
          }
        }

        SectionHeader { text: "ACCOUNTS"; visible: root.accounts.length > 0 }

        Repeater {
          model: root.accounts

          delegate: Card {
            id: row
            required property var modelData
            readonly property bool unread: modelData.unread > 0
            stripe: modelData.stale ? root.colors.red : (row.unread ? root.accent : root.colors.grey)
            implicitHeight: Math.max(address.implicitHeight, number.implicitHeight) + Style.space(18)

            Text {
              id: icon
              anchors { left: parent.left; verticalCenter: parent.verticalCenter }
              width: Style.space(18)
              text: root.accountGlyph(row.modelData.email)
              color: root.colors.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            Text {
              id: address
              anchors {
                left: icon.right; leftMargin: Style.space(6)
                right: number.left; rightMargin: Style.space(8)
                verticalCenter: parent.verticalCenter
              }
              text: row.modelData.email
              color: root.colors.text
              elide: Text.ElideRight
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              id: number
              anchors { right: parent.right; verticalCenter: parent.verticalCenter }
              text: row.modelData.unread === null ? "?" : String(row.modelData.unread)
              color: row.modelData.stale ? root.colors.red : (row.unread ? root.accent : root.colors.muted)
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
          }
        }

        Card {
          Layout.topMargin: Style.space(8)
          visible: root.reason === "login"
          stripe: root.accent
          clickable: true
          implicitHeight: signInLabel.implicitHeight + Style.space(18)
          onActivated: { if (root.hostWidget) root.hostWidget.signIn() }

          Text {
            id: signInLabel
            anchors.verticalCenter: parent.verticalCenter
            text: "SIGN IN"
            color: root.colors.text
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            font.letterSpacing: 1
          }

          Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: "opens a terminal"
            color: root.colors.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Card {
          Layout.topMargin: Style.space(8)
          stripe: root.accent
          clickable: true
          disabled: root.url === "" || root.reason === "unreachable"
          implicitHeight: openLabel.implicitHeight + Style.space(18)
          onActivated: root.openWebmail()

          Text {
            id: openLabel
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xF01EE) + "  OPEN WEBMAIL"
            color: root.colors.text
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            font.letterSpacing: 1
          }

          Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: root.url.replace(/^https?:\/\//, "")
            color: root.colors.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
