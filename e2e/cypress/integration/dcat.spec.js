describe('DCAT Extension', () => {
    it('Datasets have an rdf endpoint', () => {
        cy.request('/dataset/data-gov-statistics-parent.rdf').should(
            (response) => {
                expect(response.status).to.eq(200);
                expect(response.body).to.contain('dcat:Dataset');
            }
        );
    });
});
