#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QTimer>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("jian"));
    QCoreApplication::setApplicationVersion(QStringLiteral(JIAN_VERSION));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("简"));
    QGuiApplication::setDesktopFileName(QStringLiteral("io.github.rangerzy.jian"));

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.loadFromModule("Jian", "Main");

    // Exercise the same startup path in CI, then close without user interaction.
    if (app.arguments().contains(QStringLiteral("--smoke-test"))) {
        QTimer::singleShot(1000, &app, &QCoreApplication::quit);
    }

    return app.exec();
}
