import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// MailFlow: an envelope with the number of unread messages in the bar.
//
//   no unread mail   outlined envelope, bar colour
//   unread mail      filled envelope + count, accent colour
//   fault            outlined envelope, red (not signed in, unreachable, out of date)
//
// A click opens the panel with the counts per account, a sign-in tile when needed
// and a tile to the web app. All network I/O goes through scripts/mf-unread; this
// file only displays.
BarWidget {
  id: root
  moduleName: "melkweg.mailflow"

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace("file://", "")

  // Deliberately not named `data` or `state`: Item already has those.
  property var reading: null
  // "login", "unreachable" or "" (fine). Starts as "unreachable": until the first
  // line arrives there is nothing to show.
  property string reason: "unreachable"
  // The MailFlow URL from the session file; empty when not signed in.
  property string url: ""

  readonly property int total: root.reading ? root.reading.total : 0
  // Red when the numbers cannot be trusted.
  readonly property bool faulty: root.reason !== "" || (root.reading !== null && root.reading.complete !== true)

  readonly property string count: !root.faulty && root.total > 0 ? String(root.total) : ""

  function tooltip() {
    if (root.reason === "login") return "MailFlow: not signed in"
    if (root.reason !== "") return "MailFlow unreachable"
    if (root.reading.complete !== true) return "MailFlow: counts out of date"
    var lines = []
    var accounts = root.reading.accounts || []
    for (var i = 0; i < accounts.length; i++) {
      var a = accounts[i]
      lines.push(a.email + ": " + (a.unread === null ? "?" : a.unread) + (a.stale ? " (out of date)" : ""))
    }
    var head = root.total === 0 ? "No unread mail" : root.total + " unread"
    return head + "\n" + lines.join("\n")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ── Panel lifecycle ────────────────────────────────────────────────────
  // The shell looks for open/close/opened on the item that sits in the bar.
  readonly property var panel: panelLoader.item
  readonly property bool opened: panel ? panel.opened === true : false
  readonly property bool popoutSwitchClosing: panel ? panel.popoutSwitchClosing === true : false

  function open() { if (panel) panel.open() }
  function close() { if (panel) panel.close() }
  function togglePanel() { if (panel) panel.toggle() }
  function closeForPopoutSwitch() { if (panel) panel.closeForPopoutSwitch() }

  function openWebmail() {
    root.close()
    if (root.url === "") return
    Quickshell.execDetached(["xdg-open", root.url])
  }

  // Signing in needs a password and a second factor, so it runs in a terminal. The
  // poller notices the new session file within a few seconds.
  function signIn() {
    root.close()
    Quickshell.execDetached([
      "omarchy-launch-floating-terminal-with-presentation",
      "'" + root.pluginDir + "scripts/mf-unread' login"
    ])
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("reading" in target) target.reading = Qt.binding(function () { return root.reading })
    if ("reason" in target) target.reason = Qt.binding(function () { return root.reason })
    if ("url" in target) target.url = Qt.binding(function () { return root.url })
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "melkweg.mailflow"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function webmail(): void { root.openWebmail() }
    function signIn(): void { root.signIn() }
  }

  function process(line) {
    var d
    try {
      d = JSON.parse(String(line))
    } catch (e) {
      return
    }
    root.url = d.url || ""
    if (d.ok === true) {
      root.reading = d
      root.reason = ""
      return
    }
    root.reason = String(d.reason || "unreachable")
  }

  Process {
    id: counter
    command: [root.pluginDir + "scripts/mf-unread"]
    running: true
    stdout: SplitParser {
      onRead: function (line) { root.process(line) }
    }
    onRunningChanged: if (!running) restartTimer.restart()
  }

  // mf-unread keeps running through network errors by itself; this only catches a
  // process that died.
  Timer {
    id: restartTimer
    interval: 5000
    onTriggered: counter.running = true
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // The button's own label stays empty; envelope and count live in `content`,
    // because the envelope is a drawing and larger than the number.
    hasVisualContent: true
    labelVisible: false
    fixedWidth: content.implicitWidth + button.scaledHorizontalMargin * 2
    tooltipText: root.tooltip()
    foreground: root.faulty
      ? (root.bar ? root.bar.urgent : Color.urgent)
      : (root.total > 0 ? Color.accent : (root.bar ? root.bar.barForeground : Color.foreground))
    onPressed: function (mouseButton) {
      if (mouseButton === Qt.LeftButton) root.togglePanel()
    }

    Row {
      id: content
      anchors.centerIn: parent
      spacing: Style.space(4)

      EnvelopeIcon {
        anchors.verticalCenter: parent.verticalCenter
        color: button.foreground
        filled: !root.faulty && root.total > 0
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.count !== ""
        textFormat: Text.PlainText
        text: root.count
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        renderType: Text.NativeRendering
      }
    }
  }
}
