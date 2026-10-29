// SPDX-FileCopyrightText: 2026 Paolo Sereno <pablitos1024@gmail.com>
// SPDX-License-Identifier: MIT

#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtQuick/QQuickWindow>
#include <QtCore/QUrl>
#include <QtCore/QCoreApplication>
#include <QtCore/QTimer>
#include <QtCore/QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("QtQuickIndustrialWidgets Showcase");
    app.setOrganizationName("QtIndustrialWidgets");

    QString screenshotPath;
    int targetTab = -1;
    for (int i = 1; i < argc; ++i) {
        if (QString::fromLocal8Bit(argv[i]) == "--screenshot" && i + 1 < argc) {
            screenshotPath = QString::fromLocal8Bit(argv[++i]);
        } else if (QString::fromLocal8Bit(argv[i]) == "--tab" && i + 1 < argc) {
            targetTab = QString::fromLocal8Bit(argv[++i]).toInt();
        }
    }

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/qt/qml/GalleryApp/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, screenshotPath, targetTab, &engine, &app](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
            return;
        }

        if (targetTab >= 0 && obj) {
            obj->setProperty("initialTab", targetTab);
        }

        if (!screenshotPath.isEmpty()) {
            QTimer::singleShot(1000, [screenshotPath, &engine, &app]() {
                if (engine.rootObjects().isEmpty()) {
                    app.exit(1);
                    return;
                }
                auto *window = qobject_cast<QQuickWindow*>(engine.rootObjects().first());
                if (window) {
                    QImage img = window->grabWindow();
                    if (!img.isNull()) {
                        img.save(screenshotPath);
                        qDebug() << "Gallery screenshot saved to:" << screenshotPath;
                    } else {
                        qWarning() << "grabWindow() returned null image";
                    }
                }
                app.quit();
            });
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
