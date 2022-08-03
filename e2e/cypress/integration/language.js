describe('language', () => {
    it("Doesn't have french page", () => {
        cy.request({url: '/fr/dataset', failOnStatusCode: false}).its('status').should('equal', 404)
    });
})