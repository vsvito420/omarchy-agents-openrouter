import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Always-visible OpenRouter credit widget. The numbers come from
// ~/.local/bin/openrouter-agent-usage, which writes the same record the
// omarchy.agents panel reads; this widget just watches that file, runs the
// collector on a timer or on demand, and lets you paste keys straight in.
Panel {
  id: root
  moduleName: "vito.openrouter"
  ipcTarget: "vito.openrouter"

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string recordPath: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/omarchy/agents/usage/openrouter.json"
  readonly property string collector: home + "/.local/bin/openrouter-agent-usage"
  readonly property int refreshIntervalSec: Number(setting("refreshIntervalSec", 300)) || 300

  property var record: null
  property bool busy: false
  property string actionError: ""

  readonly property var balance: record && record.balance ? record.balance : null
  readonly property var spend: record && record.spend ? record.spend : null
  readonly property bool configured: !!(record && record.keyHint)
  readonly property bool editing: apiField.activeFocus || mgmtField.activeFocus

  readonly property string barText: {
    if (balance) return money(balance.remaining)
    if (spend) return money(spend.daily)
    return "—"
  }

  readonly property string statusText: {
    if (actionError !== "") return actionError
    if (!record) return "Loading"
    if (!configured) return "No API key"
    if (record.usageStatusText) return record.usageStatusText
    if (spend && spend.label) return spend.label
    return "Connected"
  }

  function money(value) {
    var n = Number(value)
    if (!isFinite(n)) return "—"
    return "$" + n.toFixed(2)
  }

  function updatedText() {
    if (!record || !record.updatedAt) return ""
    var d = new Date(record.updatedAt)
    if (isNaN(d.getTime())) return ""
    return "Updated " + Qt.formatTime(d, "HH:mm")
  }

  function refresh() {
    runCollector({}, false)
  }

  function saveKeys() {
    var env = {}
    var api = apiField.text.trim()
    var mgmt = mgmtField.text.trim()
    if (api !== "") env.OPENROUTER_SET_API_KEY = api
    if (mgmt !== "") env.OPENROUTER_SET_MANAGEMENT_KEY = mgmt
    if (Object.keys(env).length === 0) return
    runCollector(env, true)
    apiField.text = ""
    mgmtField.text = ""
    keyCatcher.forceActiveFocus()
  }

  function removeKeys() {
    runCollector({ OPENROUTER_SET_API_KEY: "", OPENROUTER_SET_MANAGEMENT_KEY: "" }, true)
  }

  function runCollector(env, save) {
    if (collectorProc.running) return
    actionError = ""
    busy = true
    collectorProc.environment = env
    collectorProc.command = save ? [collector, "--save"] : [collector]
    collectorProc.running = true
  }

  function parse(content) {
    try {
      var parsed = JSON.parse(String(content || ""))
      root.record = parsed && typeof parsed === "object" ? parsed : null
    } catch (e) {
      root.record = null
    }
  }

  FileView {
    path: root.recordPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parse(text())
    onLoadFailed: root.record = null
  }

  Process {
    id: collectorProc
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var msg = String(text || "").trim()
        if (msg !== "") root.actionError = msg.split("\n").pop()
      }
    }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode !== 0 && root.actionError === "") root.actionError = "Refresh failed"
    }
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onOpenedChanged: if (opened) { actionError = ""; refresh() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: vertical ? "󱚣" : "󱚣 " + root.barText
    slotSize: Style.bar.iconSlot * (vertical ? 1 : Math.max(1, (root.barText.length + 2) * 0.42))
    tooltipText: ""
    onPressed: function(b) {
      if (b === Qt.RightButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.editing
      onCloseRequested: root.close()
      onActivateRequested: root.refresh()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { if (t === "r") root.refresh() }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        // ---------- Hero ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroValue.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: "󱚣"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: heroValue.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "OpenRouter"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: root.statusText.toUpperCase()
              color: root.actionError !== "" ? Color.urgent : Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Text {
            id: heroValue
            textFormat: Text.PlainText
            text: root.balance ? root.money(root.balance.remaining) : (root.spend ? root.money(root.spend.daily) : "—")
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
            font.bold: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // ---------- Balance meter ----------
        Column {
          visible: !!root.balance
          width: parent.width
          spacing: Style.space(6)

          Item {
            width: parent.width
            implicitHeight: Style.space(8)

            Rectangle {
              id: track
              anchors.fill: parent
              radius: height / 2
              color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.12)
            }

            Rectangle {
              anchors.left: track.left
              anchors.verticalCenter: track.verticalCenter
              height: track.height
              radius: track.radius
              color: root.bar.foreground
              readonly property real ratio: root.balance && root.balance.funded > 0
                ? Math.max(0, Math.min(1, root.balance.remaining / root.balance.funded)) : 0
              width: Math.max(track.height, track.width * ratio)
              Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }
          }

          InfoLabel {
            text: root.balance ? root.money(root.balance.spent) + " spent of " + root.money(root.balance.funded) + " credits" : ""
          }
        }

        // ---------- Spend ----------
        Column {
          visible: !!root.spend
          width: parent.width
          spacing: Style.spacing.labelGap

          InfoPair { label: "Today"; value: root.spend ? root.money(root.spend.daily) : "" }
          InfoPair { label: "This week"; value: root.spend ? root.money(root.spend.weekly) : "" }
          InfoPair { label: "This month"; value: root.spend ? root.money(root.spend.monthly) : "" }
          InfoPair { label: "Key total"; value: root.spend ? root.money(root.spend.total) : "" }
          InfoPair {
            visible: !!(root.spend && root.spend.limit !== null && root.spend.limit !== undefined)
            label: "Key limit" + (root.spend && root.spend.limitReset ? " (" + root.spend.limitReset + ")" : "")
            value: root.spend && root.spend.limit !== null && root.spend.limit !== undefined
              ? root.money(root.spend.limitRemaining) + " of " + root.money(root.spend.limit) + " left" : ""
          }
        }

        Text {
          visible: !!(root.record && root.record.authHelpText) && root.actionError === ""
          width: parent.width
          wrapMode: Text.Wrap
          textFormat: Text.PlainText
          text: root.record ? String(root.record.authHelpText || "") : ""
          color: root.bar.foreground
          opacity: 0.6
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        // ---------- Keys ----------
        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader {
            text: "API KEY"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          InfoPair {
            label: "Current key"
            value: root.configured ? String(root.record.keyHint) + (root.record.hasManagementKey ? " · +mgmt" : "") : "none"
          }

          InfoPair {
            visible: root.configured
            label: "Stored in"
            value: {
              var store = root.record ? String(root.record.keyStore || "") : ""
              if (store === "keyring") return "󰌾 Keyring"
              if (store === "file") return "⚠ Plaintext file — run openrouter-secure-keys"
              if (store === "env") return "Environment"
              return ""
            }
          }

          TextField {
            id: apiField
            width: parent.width
            foreground: root.bar.foreground
            password: true
            placeholderText: "Paste API key (sk-or-v1-…)"
            onAccepted: root.saveKeys()
            Keys.onEscapePressed: keyCatcher.forceActiveFocus()
          }

          TextField {
            id: mgmtField
            width: parent.width
            foreground: root.bar.foreground
            password: true
            placeholderText: "Management key (optional, for credits)"
            onAccepted: root.saveKeys()
            Keys.onEscapePressed: keyCatcher.forceActiveFocus()
          }

          Row {
            id: actions
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing * 2) / 3

            Button {
              width: actions.cellWidth
              iconText: "󰆓"
              text: "Save"
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              bordered: true
              onClicked: root.saveKeys()
            }

            Button {
              width: actions.cellWidth
              iconText: "󰑐"
              iconSpinning: root.busy
              text: root.busy ? "Loading" : "Refresh"
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              bordered: true
              onClicked: root.refresh()
            }

            Button {
              width: actions.cellWidth
              iconText: "󰆴"
              text: "Remove"
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              bordered: true
              onClicked: root.removeKeys()
            }
          }

          InfoLabel { text: root.updatedText() }
        }
      }
    }
  }

  component InfoPair: Row {
    property string label: ""
    property string value: ""

    width: parent.width
    spacing: Style.space(8)

    InfoLabel { text: label }
    Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
    InfoValue { text: value }
  }

  component InfoLabel: Text {
    textFormat: Text.PlainText
    color: root.bar.foreground
    opacity: 0.6
    font.family: root.bar.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  component InfoValue: Text {
    textFormat: Text.PlainText
    color: root.bar.foreground
    font.family: root.bar.fontFamily
    font.pixelSize: Style.font.bodySmall
  }
}
