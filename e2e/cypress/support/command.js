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


Cypress.Commands.add('create_token', (userName, tokenName) => {

    cy.hide_debug_toolbar();
    if (!userName) {
        userName = Cypress.env('USER');
        cy.log(userName, process.env);
    }
    if (!tokenName) {
        tokenName = 'cypress token';
    }

    // create an API token named 'cypress token'
    cy.visit('/user/' + userName + '/api-tokens');

    cy.get('body').then($body => {
        if ($body.text().includes('cypress token')) {
            cy.log('cypress token exists. skipping token creation.');
        } else {
            const token_file = 'cypress/fixtures/api_token.json';
            cy.get('#name').type('cypress token');
            cy.get('button[value="create"]').click();
            // find the token in <code> tag and save it for later use
            // find the token id (jti) somewhere in the form
            cy.get('div.alert-success code').invoke('text').then((text1) => {
                cy.get('form[action^="/user/' + userName +'/api-tokens/"]').invoke('attr', 'action').then((text2) => {
                    const jti = text2.split('/')[4]
                    cy.writeFile(token_file, { api_token: text1, jti: jti });
                    // I am not sure why we need to wait here, but without it
                    // api call fails. Wait for token file to be ready?
                    cy.wait(1000);
                })
            });
            cy.log('cypress token created.');
        }
    });
});


Cypress.Commands.add('revoke_token', (tokenName) => {

    if (!tokenName) {
        tokenName = 'cypress token';
    }
    cy.log('Revoking cypress token.......');
    cy.fixture('api_token').then((token_data) => {
        cy.request({
            url: '/api/3/action/api_token_revoke',
            method: 'POST',
            headers: {
                'Authorization': token_data.api_token,
                'Content-Type': 'application/json'
            },
            body: '{"jti": "' + token_data.jti + '"}'
        });
    });
    const token_file = 'cypress/fixtures/api_token.json';
    cy.task('deleteFile', token_file)
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

Cypress.Commands.add('create_organization', (orgName, orgDesc) => {
    /**
     * Method to create organization via CKAN API
     * :PARAM orgName String: Name of the organization being created
     * :PARAM orgDesc String: Description of the organization being created
     * :PARAM orgTest Boolean: Control value to determine if to use UI to create organization
     *      for testing or to visit the organization creation page
     * :RETURN null:
     */

    cy.request({
        url: '/api/action/organization_create',
        method: 'POST',
        body: {
            description: orgDesc,
            title: orgName,
            name: orgName,
            save: null
        },
    });
});

Cypress.Commands.add('create_group', (groupName, groupDesc) => {
    /**
     * Method to create organization via CKAN API
     * :PARAM groupName String: Name of the organization being created
     * :PARAM groupDesc String: Description of the organization being created
     * :RETURN null:
     */

    cy.request({
        url: '/api/action/group_create',
        method: 'POST',
        body: {
            description: groupDesc,
            title: groupName,
            approval_status: 'approved',
            state: 'active',
            name: groupName,
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
   * Method to purge an dataset from the current state
   * :PARAM datasetName String: Name of the dataset to purge from the current state
   * :RETURN null:
   */
  cy.fixture('api_token').then((data) => {
    cy.request({
        url: '/api/action/package_delete',
        method: 'POST',
        headers: {
            'Authorization': data.api_token,
            'Content-Type': 'application/json'
        },
        body: {
            id: datasetName
        },
    });
  });
});


Cypress.Commands.add('delete_organization', (orgName) => {
    /**
     * Method to purge an organization from the current state
     * :PARAM orgName String: Name of the organization to purge from the current state
     * :RETURN null:
     */
    cy.fixture('api_token').then((data) => {
        cy.request({
            url: '/api/action/organization_delete',
            method: 'POST',
            headers: {
                'Authorization': data.api_token,
                'Content-Type': 'application/json'
            },
            body: {
                id: orgName? orgName: 'test-organization'
            },
        });

        cy.request({
            url: '/api/action/organization_purge',
            method: 'POST',
            headers: {
                'Authorization': data.api_token,
                'Content-Type': 'application/json'
            },
            body: {
                id: orgName? orgName: 'test-organization'
            },
        });

    });


});

Cypress.Commands.add('delete_dataset', (datasetName) => {
    /**
     * Method to purge a dataset from the current state
     * :PARAM datasetName String: Name of the dataset to purge from the current state
     * :RETURN null:
     */
    // if no datasetName is provided, use the default test-dataset
    cy.fixture('api_token').then((data) => {
        cy.request({
            url: '/api/action/dataset_purge',
            method: 'POST',
            headers: {
                'Authorization': data.api_token,
                'Content-Type': 'application/json'
            },
            body: {
                id: datasetName? datasetName: 'test-dataset'
            },
        });
    });
});

Cypress.Commands.add(
    'create_harvest_source',
    (harvestOrg, dataSourceUrl, harvestTitle, harvestDesc, harvestType, harvestPrivate, invalidTest) => {
        /**
         * Method to create a new CKAN harvest source via the CKAN harvest form
         * :PARAM harvestOrg String: name of test org to create harvest source under
         * :PARAM dataSourceUrl String: URL to source the data that will be harvested
         * :PARAM harvestTitle String: Title of the organization's harvest
         * :PARAM harvestDesc String: Description of the harvest being created
         * :PARAM harvestType String: Harvest source type. Ex: waf, datajson
         * :RETURN null:
         */
        cy.visit('/organization/' + harvestOrg);
        cy.hide_debug_toolbar();
        cy.get('a[class="btn btn-primary"]').click();
        cy.get('a[href="/harvest?organization=' + harvestOrg + '"]').click();
        cy.get('a[class="btn btn-primary"]').click();

        if (!invalidTest) {
            cy.get('#field-url').type(dataSourceUrl);
        }
        cy.get('#field-title').type(harvestTitle);
        cy.get('#field-name').then(($field_name) => {
            if ($field_name.is(':visible')) {
                $field_name.type(harvestTitle);
            }
        });

        cy.get('#field-notes').type(harvestDesc);
        cy.get('[type="radio"]').check(harvestType, { force: true });

        // Validate private_datasets defaults to Private
        cy.get('#field-private_datasets').find(':selected').contains('Private');

        cy.get('#field-private_datasets').select(harvestPrivate, { force: true });

        cy.get('input[name=save]').click({ force: true });
    }
);

Cypress.Commands.add('delete_harvest_source', (harvestName) => {
    cy.visit('/harvest/admin/' + harvestName);
    cy.wait(3000);
    cy.contains('Clear').click({ force: true });

    // Confirm harvest clear
    cy.wait(1000);
    cy.contains(/^Confirm$/).click();

    cy.wait(3000);
    cy.visit('/harvest/delete/' + harvestName + '?clear=True');
});

Cypress.Commands.add('start_harvest_job', (harvestName) => {
    cy.visit('/harvest/' + harvestName);
    cy.hide_debug_toolbar();

    cy.contains('Admin').click();
    // Wait for all pages to load, avoid bug
    // https://github.com/ckan/ckanext-harvest/issues/440
    cy.wait(3000);
    cy.get('.btn-group>.btn:first-child:not(:last-child):not(.dropdown-toggle)').click({ force: true });
    // Confirm harvest start
    cy.wait(1000);
    cy.contains(/^Confirm$/).click();

    // Confirm stop button exists, harvest is started/queued
    cy.wait(500);
    cy.contains('Stop');
});

Cypress.Commands.add('create_dataset', (ckan_dataset) => {

    cy.fixture('api_token').then((token_data) => {
        cy.fixture('ckan_dataset').then((dataset) => {
            cy.request({
                url: '/api/3/action/package_create',
                method: 'POST',
                headers: {
                    'Authorization': token_data.api_token,
                    'Content-Type': 'application/json'
                },
                body: ckan_dataset? JSON.stringify(ckan_dataset): dataset
            });
        });
    });

});

Cypress.Commands.add('create_resource', (package_id, url, name = "test-resource") => {

  cy.fixture('api_token').then((token_data) => {
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
