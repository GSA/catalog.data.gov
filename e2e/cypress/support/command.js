Cypress.Commands.add('login', (userName, password, loginTest) => {
    /**
     * Method to fill and submit the CKAN Login form
     * :PARAM userName String: user name of that will be attempting to login
     * :PARAM password String: password for the user logging in
     * :RETURN null:
     */
    cy.logout();

    if (!loginTest) {
        cy.visit('/user/login');
    }
    if (!userName) {
        userName = Cypress.env('USER');
        cy.log(userName, process.env);
    }
    if (!password) {
        password = Cypress.env('USER_PASSWORD');
    }
    cy.hide_debug_toolbar();

    cy.get('#field-login').type(userName);
    cy.get('#field-password').type(password);
    cy.get('.btn-primary').eq(0).click();
});

Cypress.Commands.add('create_token', (tokenName) => {
    // return if token already exists
    const token_data = Cypress.env('token_data');
    
    if (token_data) {
        cy.log('Token already exists. skipping token creation.');
        return;
    }
    
    cy.login();

    if (!tokenName) {
        tokenName = 'cypress token';
    }

    const userName = Cypress.env('USER');
    // create an API token named 'cypress token'
    cy.visit('/user/' + userName + '/api-tokens');

    cy.get('body').then($body => {
        cy.get('#name').type('cypress token');
        cy.get('button[value="create"]').click();
        // find the token in <code> tag and save it for later use
        // find the token id (jti) somewhere in the form
        cy.get('div.alert-success code').invoke('text').then((text1) => {
            cy.get('form[action^="/user/' + userName +'/api-tokens/"]').invoke('attr', 'action').then((text2) => {
                const jti = text2.split('/')[4]
                Cypress.env('token_data', { api_token: text1, jti: jti });
            })
        });
        cy.log('cypress token created.');
    });

});

Cypress.Commands.add('revoke_token', (tokenName) => {

    const token_data = Cypress.env('token_data');

    if (!token_data) {
        return;
    }

    if (!tokenName) {
        tokenName = 'cypress token';
    }
    cy.log('Revoking cypress token.......');
    cy.request({
        url: '/api/3/action/api_token_revoke',
        method: 'POST',
        headers: {
            'Authorization': token_data.api_token,
            'Content-Type': 'application/json'
        },
        body: {jti: token_data.jti}
    });
});

Cypress.Commands.add('logout', () => {
    cy.clearCookies();
});

Cypress.Commands.add('create_organization_ui', (orgName, orgDesc) => {
    /**
     * Method to fill out the form to create a CKAN organization
     * :PARAM orgName String: Name of the organization being created
     * :PARAM orgDesc String: Description of the organization being created
     * :PARAM orgTest Boolean: Control value to determine if to use UI to create organization
     *      for testing or to visit the organization creation page
     * :RETURN null:
     */
    cy.get('#field-name').type(orgName);
    cy.get('#field-description').type(orgDesc);
    cy.get('#field-url').then(($field_url) => {
        if ($field_url.is(':visible')) {
            $field_url.type(orgName);
        }
    });

    cy.get('button[name=save]').click();
});

Cypress.Commands.add('create_organization', (orgName, orgDesc, extras = null) => {
    /**
     * Method to create organization via CKAN API
     * :PARAM orgName String: Name of the organization being created
     * :PARAM orgDesc String: Description of the organization being created
     * :PARAM orgTest Boolean: Control value to determine if to use UI to create organization
     *      for testing or to visit the organization creation page
     * :RETURN null:
     */
    const token_data = Cypress.env('token_data');

    let request_obj = {
        url: '/api/action/organization_create',
        method: 'POST',
        headers: {
            'Authorization': token_data.api_token,
            'Content-Type': 'application/json'
        },
        body: {
            description: orgDesc,
            title: orgName,
            approval_status: 'approved',
            state: 'active',
            name: orgName,
        },
    };

    if (extras) {
        request_obj.body.extras = request_obj.body.extras.concat(extras);
    }

    cy.request(request_obj);
});


Cypress.Commands.add('create_group', (groupName, groupDesc) => {
    /**
     * Method to create organization via CKAN API
     * :PARAM groupName String: Name of the organization being created
     * :PARAM groupDesc String: Description of the organization being created
     * :RETURN null:
     */

    const token_data = Cypress.env('token_data');

    cy.request({
    url: '/api/action/group_create',
    method: 'POST',
    headers: {
        'Authorization': token_data.api_token,
        'Content-Type': 'application/json'
    },
    body: {
        name: groupName,
        title: groupName,
        description: groupDesc,
        save: null
    },
    });

});

Cypress.Commands.add('delete_group', (groupName) => {
    /**
     * Method to create organization via CKAN API
     * :PARAM groupName String: Name of the organization being created
     * :PARAM groupDesc String: Description of the organization being created
     * :RETURN null:
     */

    cy.request({
        url: '/api/action/group_purge',
        method: 'POST',
        failOnStatusCode: false,
        body: {
            id: groupName,
        },
    });
});

Cypress.Commands.add('delete_dataset', (datasetName) => {
    /**
     * Method to purge a dataset from the current state
     * :PARAM datasetName String: Name of the dataset to purge from the current state
     * :RETURN null:
     */
    const token_data = Cypress.env('token_data');
    cy.request({
        url: '/api/action/dataset_purge',
        method: 'POST',
        failOnStatusCode: false,
        headers: {
            'Authorization': token_data.api_token,
            'Content-Type': 'application/json'
        },
        body: {
            id: datasetName,
        },
    });
});

Cypress.Commands.add('delete_organization', (orgName) => {
    /**
     * Method to purge an organization from the current state
     * :PARAM orgName String: Name of the organization to purge from the current state
     * :RETURN null:
     */
    const token_data = Cypress.env('token_data');

    cy.request({
        url: '/api/action/organization_delete',
        method: 'POST',
        // failOnStatusCode: false,
        headers: {
            'Authorization': token_data.api_token,
            'Content-Type': 'application/json'
        },
        body: {
            id: orgName? orgName: 'test-organization'
        },
    });

    cy.request({
        url: '/api/action/organization_purge',
        method: 'POST',
        // failOnStatusCode: false,
        headers: {
            'Authorization': token_data.api_token,
            'Content-Type': 'application/json'
        },
        body: {
            id: orgName? orgName: 'test-organization'
        },
    });
});

Cypress.Commands.add('delete_dataset', (datasetName) => {
    /**
     * Method to purge a dataset from the current state
     * :PARAM datasetName String: Name of the dataset to purge from the current state
     * :RETURN null:
     */
    const token_data = Cypress.env('token_data');
    cy.request({
        url: '/api/action/dataset_purge',
        method: 'POST',
        // failOnStatusCode: false,
        headers: {
            'Authorization': token_data.api_token,
            'Content-Type': 'application/json'
        },
        body: {
            id: datasetName,
        },
    });
});

Cypress.Commands.add('create_dataset', (ckan_dataset) => {
    const token_data = Cypress.env('token_data');
    var options = {
        method: 'POST',
        url: '/api/3/action/package_create',
        headers: {
            'cache-control': 'no-cache',
            'content-type': 'application/json',
            'Authorization': token_data.api_token,
        },
        body: JSON.stringify(ckan_dataset),
    };

    return cy.request(options);
});

Cypress.Commands.add('create_resource', (package_id, url, name = "test-resource") => {

    const token_data = Cypress.env('token_data');

    cy.request({
        url: '/api/3/action/resource_create',
        method: 'POST',
        headers: {
            'Authorization': token_data.api_token,
            'Content-Type': 'application/json'
        },
        body: {
          "package_id": package_id,
          "url": url,
          "name": name
        }
    });

});

// Performs an XMLHttpRequest instead of a cy.request (able to send data as FormData - multipart/form-data)
Cypress.Commands.add('form_request', (method, url, formData, done) => {
    const xhr = new XMLHttpRequest();
    xhr.open(method, url);
    xhr.onload = function () {
        done(xhr);
    };
    xhr.onerror = function () {
        done(xhr);
    };
    xhr.send(formData);
});

Cypress.Commands.add('hide_debug_toolbar', () => {
    cy.get('#flDebugHideToolBarButton').then(($button) => {
        if ($button.is(':visible')) {
            cy.get('#flDebugHideToolBarButton').click();
        }
    });
});
