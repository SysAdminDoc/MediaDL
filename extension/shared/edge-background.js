if (api?.sidePanel?.setPanelBehavior) {
    api.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(() => {});
}
