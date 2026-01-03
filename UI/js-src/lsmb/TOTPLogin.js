/** @format */
/* global define */

/**
 * LedgerSMB TOTP (Two-Factor Authentication) Login Handler
 * 
 * This module extends the login process to handle TOTP verification
 * when users have two-factor authentication enabled.
 */

define([
    "dojo/_base/declare",
    "dojo/dom",
    "dojo/dom-construct",
    "dojo/on",
    "dojo/request/xhr",
    "dijit/form/ValidationTextBox",
    "dijit/form/Button"
], function (declare, dom, domConstruct, on, xhr, ValidationTextBox, Button) {
    
    var totpDialog = null;
    var pendingAuth = null;
    
    /**
     * Show TOTP input dialog
     */
    function showTOTPDialog(username, password, company, callback) {
        var loginDiv = dom.byId("login");
        
        // Clear existing content
        domConstruct.empty(loginDiv);
        
        // Create TOTP form
        var formHtml = '<div class="totp-form">' +
            '<h2>Two-Factor Authentication</h2>' +
            '<p>Enter the verification code from your authenticator app:</p>' +
            '<div class="totp-input-container">' +
            '<label for="totp-code-input">Verification Code:</label>' +
            '<input id="totp-code-input" type="text" ' +
            'data-dojo-type="dijit/form/ValidationTextBox" ' +
            'data-dojo-props="required:true, pattern:\'[0-9]{6}\', ' +
            'invalidMessage:\'Code must be 6 digits\'" ' +
            'maxlength="6" style="width: 150px;" />' +
            '</div>' +
            '<div class="totp-buttons">' +
            '<button id="totp-verify-btn" type="button" ' +
            'data-dojo-type="dijit/form/Button">Verify</button>' +
            '<button id="totp-cancel-btn" type="button" ' +
            'data-dojo-type="dijit/form/Button">Cancel</button>' +
            '</div>' +
            '<div id="totp-error" class="error" style="display:none; color:red; margin-top:10px;"></div>' +
            '</div>';
        
        domConstruct.place(formHtml, loginDiv);
        
        // Parse widgets
        require(["dojo/parser"], function(parser) {
            parser.parse(loginDiv);
            
            // Add event handlers
            var verifyBtn = dijit.byId("totp-verify-btn");
            var cancelBtn = dijit.byId("totp-cancel-btn");
            var codeInput = dijit.byId("totp-code-input");
            
            if (verifyBtn) {
                verifyBtn.on("click", function() {
                    var code = codeInput.get("value");
                    if (code && code.length === 6) {
                        callback(code);
                    } else {
                        showError("Please enter a valid 6-digit code");
                    }
                });
            }
            
            if (cancelBtn) {
                cancelBtn.on("click", function() {
                    // Reload the page to go back to login
                    window.location.reload();
                });
            }
            
            // Allow Enter key to submit
            if (codeInput) {
                codeInput.on("keypress", function(evt) {
                    if (evt.keyCode === 13) { // Enter key
                        verifyBtn.onClick();
                    }
                });
                
                // Focus the input
                setTimeout(function() {
                    codeInput.focus();
                }, 100);
            }
        });
    }
    
    /**
     * Show error message
     */
    function showError(message) {
        var errorDiv = dom.byId("totp-error");
        if (errorDiv) {
            errorDiv.innerHTML = message;
            errorDiv.style.display = "block";
        }
    }
    
    /**
     * Perform authentication with TOTP code
     */
    function authenticateWithTOTP(username, password, company, totpCode) {
        var authURL = "login.pl?action=authenticate";
        
        xhr.post(authURL, {
            data: JSON.stringify({
                login: username,
                password: password,
                company: company,
                totp_code: totpCode
            }),
            handleAs: "json",
            headers: {
                "Content-Type": "application/json"
            }
        }).then(
            function (data) {
                // Success - redirect
                if (data.target) {
                    window.location.assign(data.target);
                } else {
                    showError("Unexpected response from server");
                }
            },
            function (err) {
                var status = err.response.status;
                var data = err.response.data || {};
                
                if (status === 401 || status === 403) {
                    if (data.locked) {
                        showError("Account locked due to too many failed attempts. Please try again later.");
                    } else if (data.totp_required) {
                        showError("Invalid verification code. Please try again.");
                    } else {
                        showError("Authentication failed");
                    }
                } else {
                    showError("Error: " + status);
                }
            }
        );
    }
    
    /**
     * Intercept login attempts to check for TOTP requirement
     */
    function interceptLogin(username, password, company, originalCallback) {
        var authURL = "login.pl?action=authenticate";
        
        // First attempt without TOTP code
        xhr.post(authURL, {
            data: JSON.stringify({
                login: username,
                password: password,
                company: company
            }),
            handleAs: "json",
            headers: {
                "Content-Type": "application/json"
            }
        }).then(
            function (data) {
                // Success without TOTP
                if (data.target) {
                    window.location.assign(data.target);
                }
            },
            function (err) {
                var status = err.response.status;
                var headers = err.response.headers || {};
                var data = err.response.data || {};
                
                // Check if TOTP is required
                if (headers["x-ledgersmb-totp-required"] === "1" || 
                    data.totp_required) {
                    // Show TOTP dialog
                    showTOTPDialog(username, password, company, function(code) {
                        authenticateWithTOTP(username, password, company, code);
                    });
                } else {
                    // Other error, call original callback
                    if (originalCallback) {
                        originalCallback(err);
                    }
                }
            }
        );
    }
    
    return {
        interceptLogin: interceptLogin,
        showTOTPDialog: showTOTPDialog,
        authenticateWithTOTP: authenticateWithTOTP
    };
});
