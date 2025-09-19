let orgName = `org-${cy.helpers.randomSlug()}`;
let groupName = `group-${cy.helpers.randomSlug()}`;


describe('Facets', { testIsolation: false }, () => {
    before(() => {
        cy.login();
        cy.create_token();
        cy.create_organization(orgName);
        cy.create_group(groupName, "some group description");
    });

    after(() => {
        // cy.delete_organization('org-tags');
        // cy.delete_group('group-facets');
        cy.revoke_token();
        cy.logout();
    });

    it('Show datagov facet list on dataset page', () => {
        cy.visit('/dataset');
        cy.get('.filters h2').its('length').should('be.equal', 7);
        cy.get('.filters h2').first().contains('Topics');
        cy.get('.filters h2').last().contains('Bureaus');
    });

    it('Show datagov facet list on organization page', () => {
        cy.visit('/organization');
        cy.get('a[class="btn btn-primary"]').click();
        cy.visit('/organization/' + orgName);
        cy.get('.module-shallow').its('length').should('be.equal', 7);
        cy.get('.module-shallow').contains('Topics');
        cy.get('.module-shallow').contains('Harvest Source');
        cy.get('.module-shallow').last().contains('Bureaus');
    });

    it('Show datagov facet list on group page', () => {
        cy.visit('/group/' + groupName);
        cy.get('.filters h2').its('length').should('be.equal', 6);
        cy.get('.filters h2').first().contains('Categories');
        cy.get('.filters h2').last().contains('Organizations');
    });

    // https://github.com/GSA/datagov-deploy/issues/3672
    it('Can visit organization and group facet link', () => {
        cy.visit('/organization/' + orgName + '?tags=_');
        cy.visit('/group/' + groupName + '?tags=_');
    });
});
