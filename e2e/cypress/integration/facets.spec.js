describe('Facets', () => {
    before(() => {
        cy.logout()
        cy.login()
    })
    beforeEach(() => {
        Cypress.Cookies.preserveOnce('auth_tkt', 'ckan')
    })

    it('Show datagov facet list on dataset page', () => {
        cy.visit('/dataset');
        cy.get('.filters h2').its('length').should('be.equal', 9)
        cy.get('.filters h2').first().contains('Topics');
        cy.get('.filters h2').last().contains('Bureaus');
    });

    it('Show datagov facet list on organization page', () => {
        cy.create_organization('org-tags', '');
        cy.visit('/organization/org-tags');
        cy.get('.filters h2').its('length').should('be.equal', 10)
        cy.get('.filters h2').first().contains('Topics');
        cy.get('.filters h2').contains('Harvest Source');
        cy.get('.filters h2').last().contains('Bureaus');
        cy.delete_organization('org-tags');
    });

    it('Show datagov facet list on group page', () => {
        cy.create_group('group-facets');
        cy.visit('/group/group-facets');
        cy.get('.filters h2').its('length').should('be.equal', 6)
        cy.get('.filters h2').first().contains('Categories');
        cy.get('.filters h2').last().contains('Organizations');
        cy.delete_group('group-facets');
    });
});
