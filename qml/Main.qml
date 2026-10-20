import QtQuick

Window {
    width: 640
    height: 480
    visible: true
    title: "jian — 简"

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Hello World"
            font.pixelSize: 28
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "简，编联而成册"
            font.pixelSize: 18
        }
    }
}
