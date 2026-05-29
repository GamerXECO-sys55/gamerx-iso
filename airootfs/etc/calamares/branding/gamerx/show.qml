/* GamerX OS · Calamares slideshow (minimal) */
import QtQuick 2.5
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Image {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            anchors.verticalCenterOffset: -40
            width: 240; height: 240
            fillMode: Image.PreserveAspectFit
            source: "logo.png"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: 24
            text: "Welcome to GamerX OS"
            font.pixelSize: 26
            font.bold: true
            color: "#E6EAF8"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32
            text: "Installing... thanks for trying GamerX."
            font.pixelSize: 14
            color: "#8A93B8"
        }
    }

    function onActivate() {}
    function onLeave() {}
}
