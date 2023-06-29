describe('Facets', { testIsolation: false }, () => {
    before(() => {
        cy.login();
    });

    after(() => {
        cy.delete_organization('org-tags');
        cy.delete_group('group-facets');
        cy.logout();
    });

    it('Show datagov facet list on dataset page', () => {
        cy.visit('/dataset');
        cy.get('.filters h2').its('length').should('be.equal', 9);
        cy.get('.filters h2').first().contains('Topics');
        cy.get('.filters h2').last().contains('Bureaus');
    });

    it('Show datagov facet list on organization page', () => {
        cy.visit('/organization');
        cy.get('a[class="btn btn-primary"]').click();
        cy.create_organization_ui('org-tags', 'tags for org test');
        cy.visit('/organization/org-tags');
        cy.get('.module .module-narrow .module-shallow').its('length').should('be.equal', 11);
        cy.get('.module .module-narrow .module-shallow').second().contains('Topics');
        cy.get('.module .module-narrow .module-shallow'').contains('Harvest Source');
        cy.get('.module .module-narrow .module-shallow'').last().contains('Bureaus');
    });

    it('Show datagov facet list on group page', () => {
        cy.create_group('group-facets');
        cy.visit('/group/group-facets');
        cy.get('.filters h2').its('length').should('be.equal', 6);
        cy.get('.filters h2').first().contains('Categories');
        cy.get('.filters h2').last().contains('Organizations');
    });

    // https://github.com/GSA/datagov-deploy/issues/3672
    it('Can visit organization and group facet link', () => {
        cy.visit('/organization/org-tags?tags=_');
        cy.visit('/group/group-facets?tags=_');
    });
});
