import React from 'react';
import {createRoot} from 'react-dom/client';
import {BrowserRouter,Routes,Route} from 'react-router-dom';
import {HelmetProvider} from 'react-helmet-async';
import App from './App.jsx';
import {SoftwareList,ProductPage,CapabilityPage,ComparePage} from './PublicPages.jsx';
import './styles.css';

createRoot(document.getElementById('root')).render(
  <React.StrictMode><HelmetProvider><BrowserRouter><Routes>
    <Route path="/" element={<App/>}/>
    <Route path="/software" element={<SoftwareList/>}/>
    <Route path="/software/:slug" element={<ProductPage/>}/>
    <Route path="/capabilities/:slug" element={<CapabilityPage/>}/>
    <Route path="/compare/:pair" element={<ComparePage/>}/>
    <Route path="/advice" element={<App/>}/>
  </Routes></BrowserRouter></HelmetProvider></React.StrictMode>
);
