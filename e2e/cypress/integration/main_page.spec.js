describe('Main Page', () => {
    it('Redirects from / to /dataset', () => {
        cy.visit('/');
        cy.url().should('be.equal', `${Cypress.config('baseUrl')}/dataset`);
    });

    it('Load main page with configuration', () => {
        cy.visit('/dataset');
        cy.contains('Data Catalog');
    });

    it('google tracker injected', () => {
        cy.request('/dataset').then((response) => {
            expect(response.body).to.have.string('UA-1010101-1');
        });
    });
});
