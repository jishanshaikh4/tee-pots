// This script will be injected in to the WebView created by QuicksilverCardFragment and used by
// QuicksilverCardFragment.AutoDelegateImpl to retrieve strings and perform click actions.

var primaryButton = document.querySelector('[data-click-to-action-id="primaryCta"]');
var legalLink = document.querySelector('[data-click-to-action-id="legalCta"]');
var legal = document.querySelector('.UpsellWebview-legal');
var fullscreenLegal = document.querySelector('.ShowcaseWebview-legal');
var dismissButton = document.querySelector('[data-click-to-action-id="dismissCta"]');
var header = document.querySelector('.ShowcaseWebview-heading');
var fullscreenMessage = document.querySelector('.ShowcaseWebview-message');
var message = document.querySelector('.UpsellWebview-message');
var title = document.querySelector('.UpsellWebview-title');

function clickPrimaryButton() {
    var event = new MouseEvent('click', {
        view: window,
        bubbles: true,
        cancelable: true
    });

    primaryButton.dispatchEvent(event);
}

function clickLegalLink() {
    var event = new MouseEvent('click', {
                               view: window,
                               bubbles: true,
                               cancelable: true
                               });

    legalLink.dispatchEvent(event);
}

function clickDismissButton() {
    var event = new MouseEvent('click', {
                               view: window,
                               bubbles: true,
                               cancelable: true
                               });

    dismissButton.dispatchEvent(event);
}

function getPrimaryButtonText() {
    return primaryButton.innerText;
}

function getLegalText() {
    return legal.innerText;
}

function getFullscreenLegalText() {
    return fullscreenLegal.innerText;
}

function getHeaderText() {
    return header.innerText;
}

function getFooterText() {
    return dismissButton.innerText;
}

function getTitleText() {
    return title.innerText;
}

function getModalMessageText() {
    return message.innerText;
}

function getFullscreenMessageText() {
    return fullscreenMessage.innerText;
}
