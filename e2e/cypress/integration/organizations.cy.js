describe('Organization', { testIsolation: false }, () => {
    before(() => {
        cy.login();
    });

    after(() => {
        cy.delete_organization('cypress-test-org');
        cy.logout();
    });

    it('Create Organization', () => {
        cy.visit('/organization');
        cy.get('a[class="btn btn-primary"]').click();
        cy.create_organization_ui('cypress-test-org', 'cypress test description');
        cy.visit('/organization/cypress-test-org');
    });

    it('Contains Organization Information', () => {
        cy.contains('No datasets found');
        cy.contains('cypress test description');
        cy.contains('0');
        cy.get('a[href="/organization/cypress-test-org"]');
    });

    it('Edit Organization Description', () => {
        cy.visit('/organization/edit/cypress-test-org');
        cy.get('#field-description').clear();
        cy.get('#field-description').type('the new description');
        cy.hide_debug_toolbar();

        cy.get('button[name=save]').click();
    });

    it('Edit Organization with Custom Field', () => {
        cy.visit('/organization/edit/cypress-test-org');
        cy.get('#field-extras-1-key').type('organization_type');
        cy.get('#field-extras-1-value').type('Federal Government');
        cy.hide_debug_toolbar();

        cy.get('button[name=save]').click();
    });

    it('Verify Organization Type Banner', () => {
        cy.visit('/organization/cypress-test-org');

        cy.get('.organization-type')
            .should('have.attr', 'title', 'Federal Government')
            .and('have.attr', 'data-organization-type', 'federal');

        cy.get('.organization-type span').should('contain', 'Federal');
    });
});
