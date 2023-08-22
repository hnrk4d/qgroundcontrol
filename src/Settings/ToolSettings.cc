/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ToolSettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(Tool, "Tool")
{
    qmlRegisterUncreatableType<ToolSettings>("QGroundControl.SettingsManager", 1, 0, "ToolSettings", "Reference only");
}

DECLARE_SETTINGSFACT(ToolSettings, tool)
