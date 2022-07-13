describe('Collection', () => {

    it('Has a UI search button', () => {
        cy.visit('/dataset/data-gov-statistics-parent');
        cy.hide_debug_toolbar();
        // Click on the "Search within this collection" button
        cy.contains('Search datasets within this collection').click();
        cy.url().should('include', '?collection_package_id')
    })

})
